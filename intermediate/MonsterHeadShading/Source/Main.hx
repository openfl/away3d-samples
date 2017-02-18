/*

Monster Head example in Away3d

Demonstrates:

How to use the AssetLibrary to load an internal AWD model.
How to set custom material methods on a model.
How to setup soft shadows and multiple lightsources with a multipass texture
How to use a diffuse gradient method as a cheap way to simulate sub-surface scattering

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package;

import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.lights.shadowmaps.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.textures.*;
import away3d.utils.*;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.net.*;
import openfl.text.*;
import openfl.utils.*;
import openfl.Vector;

//import uk.co.soulwire.gui.*;

class Main extends Sprite
{
	//textures
	private static var _textureStrings:Vector<String> = Vector.ofArray(["monsterhead_diffuse.jpg", "monsterhead_specular.jpg", "monsterhead_normals.jpg"]);
	private var _textureDictionary:Map<String, Dynamic> = new Map();
	
	//engine variables
	private var _scene:Scene3D;
	private var _camera:Camera3D;
	private var _view:View3D;
	private var _cameraController:HoverController;
	private var _awayStats:AwayStats;
	private var _text:TextField;
	
	//gui variables
	private var _shadowRange:Float = 3;
	private var _lightDirection:Float = 120*Math.PI/180;
	private var _lightElevation:Float = 30*Math.PI/180;
	private var _guiContainer:Sprite;
	//private var _gui:SimpleGUI;
	
	//material objects
	private var _headMaterial:TextureMultiPassMaterial;
	private var _softShadowMethod:SoftShadowMapMethod;
	private var _fresnelMethod:FresnelSpecularMethod;
	//private var _diffuseMethod:BasicDiffuseMethod;
	//private var _specularMethod:BasicSpecularMethod;
	
	//scene objects
	private var _blueLight:PointLight;
	private var _redLight:PointLight;
	private var _directionalLight:DirectionalLight;
	private var _lightPicker:StaticLightPicker;
	private var _headModel:Mesh;
	private var _advancedMethod:Bool = true;
	
	//loading variables
	private var _numTextures:Int = 0;
	private var _currentTexture:Int = 0;
	private var _n:Int = 0;
	private var _loadingText:String;
	
	//root filepath for asset loading
	private var _assetsRoot:String = "assets/monsterhead/";
	
	//navigation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;
	
	
	/**
	 * GUI variable for setting the shadow range value
	 */
	public var shadowRange(get, set):Float;
	private function get_shadowRange():Float
	{
		return _shadowRange;
	}
	
	private function set_shadowRange(value:Float):Float
	{
		_shadowRange = value;
		
		updateRange();
		return value;
	}
	
	/**
	 * GUI variable for setting the direction of the directional lightsource
	 */
	public var lightDirection(get, set):Float;
	private function get_lightDirection():Float
	{
		return _lightDirection*180/Math.PI;
	}
	
	private function set_lightDirection(value:Float):Float
	{
		_lightDirection = value*Math.PI/180;
		
		updateDirection();
		return value;
	}
	
	/**
	 * GUI variable for setting The elevation of the directional lightsource
	 */
	public var lightElevation(get, set):Float;
	private function get_lightElevation():Float
	{
		return 90 - _lightElevation*180/Math.PI;
	}
	
	private function set_lightElevation(value:Float):Float
	{
		_lightElevation = (90 - value)*Math.PI/180;
		
		updateDirection();
		return value;
	}
	
	/**
	 * Constructor
	 */
	public function new()
	{
		super();
		init();
	}
	
	/**
	 * Global initialise function
	 */
	private function init():Void
	{
		initEngine();
		initText();
		initLights();
		initGUI();
		initListeners();
		
		//kickoff asset loading
		_n = 0;
		_numTextures = _textureStrings.length;
		load(_textureStrings[_n]);
	}
	
	/**
	 * Initialise the engine
	 */
	private function initEngine():Void
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		_scene = new Scene3D();
		
		_camera = new Camera3D();
		_camera.lens.near = 20;
		_camera.lens.far = 1000;
		
		_view = new View3D();
		_view.antiAlias = 4;
		_view.scene = _scene;
		_view.camera = _camera;
		
		//setup controller to be used on the camera
		_cameraController = new HoverController(_camera, null, 225, 10, 800);
		_cameraController.yFactor = 1;
		
		addChild(_view);
		
		//add stats
		addChild(_awayStats = new AwayStats(_view));
	}
	
	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		_text = new TextField();
		_text.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF, null, null, null, null, null, "center");
		_text.embedFonts = true;
		_text.antiAliasType = AntiAliasType.ADVANCED;
		_text.gridFitType = GridFitType.PIXEL;
		_text.width = 300;
		_text.height = 250;
		_text.selectable = false;
		_text.mouseEnabled = true;
		_text.wordWrap = true;
		//_text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		addChild(_text);
	}
	
	/**
	 * Initialise the lights in a scene
	 */
	private function initLights():Void
	{
		//var initialAzimuth : Float = .6;
		//var initialArc : Float = 2;
		var x : Float = Math.sin(_lightElevation)*Math.cos(_lightDirection);
		var y : Float = -Math.cos(_lightElevation);
		var z : Float = Math.sin(_lightElevation)*Math.sin(_lightDirection);
		
		// main light casting the shadows
		_directionalLight = new DirectionalLight(x, y, z);
		_directionalLight.color = 0xffeedd;
		_directionalLight.ambient = 1;
		_directionalLight.specular = .3;
		_directionalLight.ambientColor = 0x101025;
		_directionalLight.castsShadows = true;
		cast(_directionalLight.shadowMapper, DirectionalShadowMapper).lightOffset = 1000;
		_scene.addChild(_directionalLight);
		
		// blue point light coming from the right
		_blueLight = new PointLight();
		_blueLight.color = 0x4080ff;
		_blueLight.x = 3000;
		_blueLight.z = 700;
		_blueLight.y = 20;
		_scene.addChild(_blueLight);
		
		// red light coming from the left
		_redLight = new PointLight();
		_redLight.color = 0x802010;
		_redLight.x = -2000;
		_redLight.z = 800;
		_redLight.y = -400;
		_scene.addChild(_redLight);
		
		_lightPicker = new StaticLightPicker([_directionalLight, _blueLight, _redLight]);
		
	}
	
	/**
	 * Initialise the GUI
	 */
	private function initGUI():Void
	{
		_guiContainer = new Sprite();
		_guiContainer.addEventListener(MouseEvent.MOUSE_DOWN, blockMouseDown);
		addChild(_guiContainer);
		
		//_gui = new SimpleGUI(_guiContainer, "");
		//_gui.addColumn("Instructions");
		//var instr:String = "Click and drag on the stage to rotate camera.\n";
		//instr += "Keyboard arrows and WASD to move.\n";
		//_gui.addLabel(instr);
		
		//_gui.addColumn("Material Settings");
		//_gui.addToggle("singlePassMaterial", {label:"Single pass"});
		//_gui.addToggle("multiPassMaterial", {label:"Multiple pass"});
		
		//_gui.addColumn("Shadow Settings");
		//_gui.addSlider("parent.shadowRange", 1, 50, {label:"Range", tick:0.1});
		
		
		//_gui.addColumn("Light Position");
		//_gui.addSlider("parent.lightDirection", 0, 360, {label:"Direction", tick:0.1});
		//_gui.addSlider("parent.lightElevation", -90, 90, {label:"Elevation", tick:0.1});
		//_gui.show();
	}
	
	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}
	
	/**
	 * Updates the direction of the directional lightsource
	 */
	private function updateDirection():Void
	{
		_directionalLight.direction = new Vector3D(
			Math.sin(_lightElevation)*Math.cos(_lightDirection),
			-Math.cos(_lightElevation),
			Math.sin(_lightElevation)*Math.sin(_lightDirection)
		);
	}
	
	private function updateRange():Void
	{
		_softShadowMethod.range = _shadowRange;
	}
	
	/**
	 * Global binary file loader
	 */
	private function load(url:String):Void
	{
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		
		switch (url.substring(url.length - 3)) {
			case "AWD", "awd": 
				_loadingText = "Loading Model";
				loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
			case "png", "jpg": 
				_currentTexture++;
				_loadingText = "Loading Textures";
				loader.addEventListener(Event.COMPLETE, parseBitmap);
		}
		
		loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
		loader.load(new URLRequest(_assetsRoot+url));
		
	}
	
	/**
	 * Display current load
	 */
	private function loadProgress(e:ProgressEvent):Void
	{
		var P:Int = Std.int(e.bytesLoaded / e.bytesTotal * 100);
		if (P != 100) {
			log(_loadingText + '\n' + ((_loadingText == "Loading Model")? (Std.int(e.bytesLoaded / 1024) << 0) + 'kb | ' + (Std.int(e.bytesTotal / 1024) << 0) + 'kb' : _currentTexture + ' | ' + _numTextures));
		} else if (_loadingText == "Loading Model") {
			_text.visible = false;
		}
	}
	
	/**
	 * Parses the Bitmap file
	 */
	private function parseBitmap(e:Event):Void 
	{
		var urlLoader:URLLoader = cast(e.target, URLLoader);
		var loader:Loader = new Loader();
		loader.loadBytes(urlLoader.data);
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
		urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
		urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
		loader = null;
	}
	
	/**
	 * Parses the AWD file
	 */
	private function parseAWD(e:Event):Void
	{
		log("Parsing Data");
		var loader:URLLoader = cast(e.target, URLLoader);
		
		//setup parser
		Asset3DLibrary.enableParser(AWDParser);
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		Asset3DLibrary.loadData(loader.data, new AssetLoaderContext(false));
		
		loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
		loader.removeEventListener(Event.COMPLETE, parseAWD);
		loader = null;
	}
	
	/**
	 * log for display info
	 */
	private function log(t:String):Void
	{
		_text.htmlText = t;
		_text.visible = true;
	}
	
	/**
	 * Listener function for bitmap complete event on loader
	 */
	private function onBitmapComplete(e:Event):Void
	{
		var loaderInfo:LoaderInfo = cast e.target;
		var loader:Loader = loaderInfo.loader;
		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBitmapComplete);
		
		//create bitmap texture in dictionary
		if (!_textureDictionary.exists(_textureStrings[_n]))
			_textureDictionary[_textureStrings[_n]] = (_n == 1)? new SpecularBitmapTexture(cast(loaderInfo.content, Bitmap).bitmapData) : Cast.bitmapTexture(loaderInfo.content);
		
		loader.unload();
		loader = null;
		
		_n++;
		
		//switch to next teture set
		if (_n < _textureStrings.length) {
			load(_textureStrings[_n]);
		} else {
			load("MonsterHead.awd");
		}
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		if (_move) {
			_cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
			_cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
		}
		
		_view.render();
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.MESH) {
			_headModel = cast event.asset;
			_headModel.geometry.scale(4); //TODO scale cannot be performed on mesh when using sub-surface diffuse method
			_headModel.y = -20;
			_scene.addChild(_headModel);
		}
	}
	
	/**
	 * Triggered once all resources are loaded
	 */
	private function onResourceComplete(e:LoaderEvent):Void
	{
		_text.visible = false;
		
		Asset3DLibrary.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		
		//setup custom multipass material
		_headMaterial = new TextureMultiPassMaterial(_textureDictionary["monsterhead_diffuse.jpg"]);
		_headMaterial.normalMap = _textureDictionary["monsterhead_normals.jpg"];
		_headMaterial.lightPicker = _lightPicker;
		_headMaterial.ambientColor = 0x303040;
		
		// create soft shadows with a lot of samples for best results. With the current method setup, any more samples would fail to compile
		_softShadowMethod = new SoftShadowMapMethod(_directionalLight, 30);
		_softShadowMethod.range = _shadowRange;	// the sample radius defines the softness of the shadows
		_softShadowMethod.epsilon = .1;
		_headMaterial.shadowMethod = _softShadowMethod;
		
		// create specular reflections that are stronger from the sides
		_fresnelMethod = new FresnelSpecularMethod(true);
		_fresnelMethod.fresnelPower = 3;
		_headMaterial.specularMethod = _fresnelMethod;
		_headMaterial.specularMap = _textureDictionary["monsterhead_specular.jpg"];
		_headMaterial.specular = 3;
		_headMaterial.gloss = 10;
		
		// very low-cost and crude subsurface scattering for diffuse shading
		_headMaterial.diffuseMethod = new GradientDiffuseMethod(Cast.bitmapTexture("assets/diffuseGradient.jpg"));
		
		//apply material to head model
		for (subMesh in _headModel.subMeshes)
			subMesh.material = _headMaterial;
	}
	
	/**
	 * Prevent interaction with UI to trigger interaction updates
	 */
	private function blockMouseDown(event : MouseEvent) : Void
	{
		event.stopImmediatePropagation();
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent):Void
	{
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
		_move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse up listener for navigation
	 */
	private function onMouseUp(event:MouseEvent):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Key up listener for swapping between standard diffuse & specular shading, and sub-surface diffuse shading with fresnel specular shading
	 */
	private function onKeyUp(event:KeyboardEvent):Void
	{
		if (_headMaterial == null) return;
		
		_advancedMethod = !_advancedMethod;
		
		_headMaterial.gloss = (_advancedMethod)? 10 : 50;
		_headMaterial.specular = (_advancedMethod)? 3 : 1;
	}
	
	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
		
		_text.x = (stage.stageWidth - _text.width)/2;
		_text.y = (stage.stageHeight - _text.height)/2;
		
		_awayStats.x = stage.stageWidth - _awayStats.width;
	}
}