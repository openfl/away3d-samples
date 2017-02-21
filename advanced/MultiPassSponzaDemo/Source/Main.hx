/*

Crytek Sponza demo using multipass materials in Away3D

Demonstrates:

How to apply Multipass materials to a model
How to enable cascading shadow maps on a multipass material.
How to setup multiple lightsources, shadows and fog effects all in the same scene.
How to apply specular, normal and diffuse maps to an AWD model.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

Model re-modeled by Frank Meinl at Crytek with inspiration from Marko Dabrovic's original, converted to AWD by LoTH
contact@crytek.com
http://www.crytek.com/cryengine/cryengine3/downloads
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

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

import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.lights.shadowmaps.*;
import away3d.loaders.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.tools.commands.*;
import away3d.utils.*;

//import uk.co.soulwire.gui.*;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.net.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.*;
import openfl.Assets;
import openfl.Vector;

class Main extends Sprite
{
	public var singlePassMaterial(get, set):Bool;
	public var multiPassMaterial(get, set):Bool;
	public var cascadeLevels(get, set):Int;
	public var shadowOptions(get, set):String;
	public var depthMapSize(get, set):Int;
	public var lightDirection(get, set):Float;
	public var lightElevation(get, set):Float;
	
	//root filepath for asset loading
	private var _assetsRoot:String = "assets/";
	
	//default material data strings
	private var _materialNameStrings:Vector<String> = Vector.ofArray(["arch",            "Material__298",  "bricks",            "ceiling",            "chain",             "column_a",          "column_b",          "column_c",          "fabric_g",              "fabric_c",         "fabric_f",               "details",          "fabric_d",             "fabric_a",        "fabric_e",              "flagpole",          "floor",            "16___Default","Material__25","roof",       "leaf",           "vase",         "vase_hanging",     "Material__57",   "vase_round"]);
	
	//private const diffuseTextureStrings:Vector<String> = Vector.ofArray(["arch_diff.atf", "background.atf", "bricks_a_diff.atf", "ceiling_a_diff.atf", "chain_texture.png", "column_a_diff.atf", "column_b_diff.atf", "column_c_diff.atf", "curtain_blue_diff.atf", "curtain_diff.atf", "curtain_green_diff.atf", "details_diff.atf", "fabric_blue_diff.atf", "fabric_diff.atf", "fabric_green_diff.atf", "flagpole_diff.atf", "floor_a_diff.atf", "gi_flag.atf", "lion.atf", "roof_diff.atf", "thorn_diff.png", "vase_dif.atf", "vase_hanging.atf", "vase_plant.png", "vase_round.atf"]);
	//private const normalTextureStrings:Vector<String> = Vector.ofArray(["arch_ddn.atf", "background_ddn.atf", "bricks_a_ddn.atf", null,                "chain_texture_ddn.atf", "column_a_ddn.atf", "column_b_ddn.atf", "column_c_ddn.atf", null,                   null,               null,                     null,               null,                   null,              null,                    null,                null,               null,          "lion2_ddn.atf", null,       "thorn_ddn.atf", "vase_ddn.atf",  null,               null,             "vase_round_ddn.atf"]);
	//private const specularTextureStrings:Vector<String> = Vector.ofArray(["arch_spec.atf", null,            "bricks_a_spec.atf", "ceiling_a_spec.atf", null,                "column_a_spec.atf", "column_b_spec.atf", "column_c_spec.atf", "curtain_spec.atf",      "curtain_spec.atf", "curtain_spec.atf",       "details_spec.atf", "fabric_spec.atf",      "fabric_spec.atf", "fabric_spec.atf",       "flagpole_spec.atf", "floor_a_spec.atf", null,          null,       null,            "thorn_spec.atf", null,           null,               "vase_plant_spec.atf", "vase_round_spec.atf"]);
	
	private static var _diffuseTextureStrings:Vector<String> = Vector.ofArray(["arch_diff.jpg", "background.jpg", "bricks_a_diff.jpg", "ceiling_a_diff.jpg", "chain_texture.png", "column_a_diff.jpg", "column_b_diff.jpg", "column_c_diff.jpg", "curtain_blue_diff.jpg", "curtain_diff.jpg", "curtain_green_diff.jpg", "details_diff.jpg", "fabric_blue_diff.jpg", "fabric_diff.jpg", "fabric_green_diff.jpg", "flagpole_diff.jpg", "floor_a_diff.jpg", "gi_flag.jpg", "lion.jpg", "roof_diff.jpg", "thorn_diff.png", "vase_dif.jpg", "vase_hanging.jpg", "vase_plant.png", "vase_round.jpg"]);
	private static var _normalTextureStrings:Vector<String> = Vector.ofArray(["arch_ddn.jpg", "background_ddn.jpg", "bricks_a_ddn.jpg", null,                "chain_texture_ddn.jpg", "column_a_ddn.jpg", "column_b_ddn.jpg", "column_c_ddn.jpg", null,                   null,               null,                     null,               null,                   null,              null,                    null,                null,               null,          "lion2_ddn.jpg", null,       "thorn_ddn.jpg", "vase_ddn.jpg",  null,               null,             "vase_round_ddn.jpg"]);
	private static var _specularTextureStrings:Vector<String> = Vector.ofArray(["arch_spec.jpg", null,            "bricks_a_spec.jpg", "ceiling_a_spec.jpg", null,                "column_a_spec.jpg", "column_b_spec.jpg", "column_c_spec.jpg", "curtain_spec.jpg",      "curtain_spec.jpg", "curtain_spec.jpg",       "details_spec.jpg", "fabric_spec.jpg",      "fabric_spec.jpg", "fabric_spec.jpg",       "flagpole_spec.jpg", "floor_a_spec.jpg", null,          null,       null,            "thorn_spec.jpg", null,           null,               "vase_plant_spec.jpg", "vase_round_spec.jpg"]);
	private var _numTexStrings:Vector<Int> = Vector.ofArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
	private var _meshReference:Vector<Mesh> = new Vector<Mesh>(25);
	
	//flame data objects
	private static var _flameData:Vector<FlameVO> = Vector.ofArray([new FlameVO(new Vector3D(-625, 165, 219), 0xffaa44), new FlameVO(new Vector3D(485, 165, 219), 0xffaa44), new FlameVO(new Vector3D(-625, 165, -148), 0xffaa44), new FlameVO(new Vector3D(485, 165, -148), 0xffaa44)]);
	
	//material dictionaries to hold instances
	private var _textureDictionary:Map<String, Dynamic> = new Map<String, Dynamic>();
	private var _multiMaterialDictionary:Map<String, TextureMultiPassMaterial> = new Map<String, TextureMultiPassMaterial>();
	private var _singleMaterialDictionary:Map<String, TextureMaterial> = new Map<String, TextureMaterial>();
	
	//private var meshDictionary:Dictionary = new Dictionary();
	private var vaseMeshes:Vector<Mesh> = new Vector<Mesh>();
	private var poleMeshes:Vector<Mesh> = new Vector<Mesh>();
	private var colMeshes:Vector<Mesh> = new Vector<Mesh>();
	
	//engien variables
	private var _view:View3D;
	private var _cameraController:FirstPersonController;
	private var _awayStats:AwayStats;
	private var _text:TextField;
	
	//gui variables
	private var _singlePassMaterial:Bool = false;
	private var _multiPassMaterial:Bool = true;
	private var _cascadeLevels:Int = 3;
	private var _shadowOptions:String = "PCF";
	private var _depthMapSize:Int = 2048;
	private var _lightDirection:Float = Math.PI/2;
	private var _lightElevation:Float = Math.PI/18;
	//private var _gui:SimpleGUI;
	
	//light variables
	private var _lightPicker:StaticLightPicker;
	private var _baseShadowMethod:FilteredShadowMapMethod;
	private var _cascadeMethod:CascadeShadowMapMethod;
	private var _fogMethod : FogMethod;
	private var _cascadeShadowMapper:CascadeShadowMapper;
	private var _directionalLight:DirectionalLight;
	private var _lights:Array<LightBase> = new Array<LightBase>();
	
	//material variables
	private var _skyMap:ATFCubeTexture;
	private var _flameMaterial:TextureMaterial;
	private var _numTextures:Int = 0;
	private var _currentTexture:Int = 0;
	private var _loadingTextureStrings:Vector<String>;
	private var _n:Int = 0;
	private var _loadingText:String;
	
	//scene variables
	private var _meshes:Vector<Mesh> = new Vector<Mesh>();
	private var _flameGeometry:PlaneGeometry;
			
	//rotation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;
	
	//movement variables
	private var _drag:Float = 0.5;
	private var _walkIncrement:Float = 10;
	private var _strafeIncrement:Float = 10;
	private var _walkSpeed:Float = 0;
	private var _strafeSpeed:Float = 0;
	private var _walkAcceleration:Float = 0;
	private var _strafeAcceleration:Float = 0;
	
	/**
	 * GUI variable for setting material mode to single pass
	 */
	private function get_singlePassMaterial():Bool
	{
		return _singlePassMaterial;
	}
	
	private function set_singlePassMaterial(value:Bool):Bool
	{
		_singlePassMaterial = value;
		_multiPassMaterial = !value;
		
		updateMaterialPass(value? _singleMaterialDictionary : _multiMaterialDictionary);
		return value;
	}
	
	/**
	 * GUI variable for setting material mode to multi pass
	 */
	private function get_multiPassMaterial():Bool
	{
		return _multiPassMaterial;
	}
	
	private function set_multiPassMaterial(value:Bool):Bool
	{
		_multiPassMaterial = value;
		_singlePassMaterial = !value;
		
		updateMaterialPass(value? _multiMaterialDictionary : _singleMaterialDictionary);
		return value;
	}
	
	/**
	 * GUI variable for setting number of cascade levels.
	 */
	private function get_cascadeLevels():Int
	{
		return _cascadeLevels;
	}
	
	private function set_cascadeLevels(value:Int):Int
	{
		_cascadeLevels = value;
		
		return _cascadeShadowMapper.numCascades = value;
	}
	
	/**
	 * GUI variable for setting the active shadow option
	 */
	private function get_shadowOptions():String
	{
		return _shadowOptions;
	}
	
	private function set_shadowOptions(value:String):String
	{
		_shadowOptions = value;
		
		switch(value) {
			case "Unfiltered":
				_cascadeMethod.baseMethod = new HardShadowMapMethod(_directionalLight);
			case "Multiple taps":
				_cascadeMethod.baseMethod = new SoftShadowMapMethod(_directionalLight);
			case "PCF":
				_cascadeMethod.baseMethod = new FilteredShadowMapMethod(_directionalLight);
			case "Dithered":
				_cascadeMethod.baseMethod = new DitheredShadowMapMethod(_directionalLight);
		}
		
		return value;
	}
	
	/**
	 * GUI variable for setting the depth map size of the shadow mapper.
	 */
	private function get_depthMapSize():Int
	{
		return _depthMapSize;
	}
	
	private function set_depthMapSize(value:Int):Int
	{
		_depthMapSize = value;
		
		return _directionalLight.shadowMapper.depthMapSize = value;
	}
	
	/**
	 * GUI variable for setting the direction of the directional lightsource
	 */
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
		
		
		//count textures
		_n = 0;
		_loadingTextureStrings = _diffuseTextureStrings;
		countNumTextures();
		
		//kickoff asset loading
		_n = 0;
		_loadingTextureStrings = _diffuseTextureStrings;
		load(_loadingTextureStrings[_n]);
	}
	
    /**
     * Initialise the engine
     */
	private function initEngine():Void
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
		stage.quality = StageQuality.LOW;
		
		//create the view
		_view = new View3D(null, null, null, false);
		_view.camera.y = 150;
		_view.camera.z = 0;
		
		addChild(_view);
		
		//setup controller to be used on the camera
		_cameraController = new FirstPersonController(_view.camera, 90, 0, -80, 80);			
		
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
     * Initialise the lights
     */
	private function initLights():Void
	{
		//create lights array
		_lights = new Array<LightBase>();
		
		//create global directional light
		_cascadeShadowMapper = new CascadeShadowMapper(3);
		_cascadeShadowMapper.lightOffset = 20000;
		_directionalLight = new DirectionalLight(-1, -15, 1);
		_directionalLight.shadowMapper = _cascadeShadowMapper;
		_directionalLight.color = 0xeedddd;
		_directionalLight.ambient = .35;
		_directionalLight.ambientColor = 0x808090;
		_view.scene.addChild(_directionalLight);
		_lights.push(_directionalLight);
		
		updateDirection();
		
		//creat flame lights
		for (flameVO in _flameData)
		{
			var light : PointLight = flameVO.light = new PointLight();
			light.radius = 200;
			light.fallOff = 600;
			light.color = flameVO.color;
			light.y = 10;
			_lights.push(light);
		}
		
		//create our global light picker
		_lightPicker = new StaticLightPicker(_lights);
		_baseShadowMethod = new FilteredShadowMapMethod(_directionalLight);
		
		//create our global fog method
		_fogMethod = new FogMethod(0, 4000, 0x9090e7);
		_cascadeMethod = new CascadeShadowMapMethod(_baseShadowMethod);
	}
	
    /**
     * Initialise the scene materials
     */		
	private function initMaterials():Void
	{
		//create skybox texture map
		_skyMap = new ATFCubeTexture(Assets.getBytes("assets/skybox/hourglass_cubemap.atf"));
		
		//create flame material
		//_flameMaterial = new TextureMaterial(Cast.bitmapTexture("assets/fire.atf"));
		_flameMaterial = new TextureMaterial(new ATFTexture(Assets.getBytes("assets/fire.atf")));
		_flameMaterial.blendMode = BlendMode.ADD;
		_flameMaterial.animateUVs = true;
		
	}
	        
    /**
     * Initialise the scene objects
     */
    private function initObjects():Void
	{
		//create skybox
        _view.scene.addChild(new SkyBox(_skyMap));
		
		//create flame meshes
		_flameGeometry = new PlaneGeometry(40, 80, 1, 1, false, true);
		for (flameVO in _flameData)
		{
			var mesh : Mesh = flameVO.mesh = new Mesh(_flameGeometry, _flameMaterial);
			mesh.position = flameVO.position;
			mesh.subMeshes[0].scaleU = 1/16;
			_view.scene.addChild(mesh);
			mesh.addChild(flameVO.light);
		}
	}
	
	/**
	 * Initialise the GUI
	 */
	private function initGUI():Void
	{
		/*var shadowOptions:Array = [
			{label:"Unfiltered", data:"Unfiltered"},
			{label:"PCF", data:"PCF"},
			{label:"Multiple taps", data:"Multiple taps"},
			{label:"Dithered", data:"Dithered"}
		];
		
		var depthMapSize:Array = [
			{label:"512", data:512},
			{label:"1024", data:1024},
			{label:"2048", data:2048}
		];
		
		_gui = new SimpleGUI(this, "");
		
		_gui.addColumn("Instructions");
		var instr:String = "Click and drag on the stage to rotate camera.\n";
		instr += "Keyboard arrows and WASD to move.\n";
		instr += "F to enter Fullscreen mode.\n";
		instr += "C to toggle camera mode between walk and fly.\n";
		_gui.addLabel(instr);
		
		_gui.addColumn("Material Settings");
		_gui.addToggle("singlePassMaterial", {label:"Single pass"});
		_gui.addToggle("multiPassMaterial", {label:"Multiple pass"});
		
		_gui.addColumn("Shadow Settings");
		_gui.addStepper("cascadeLevels", 1, 4, {label:"Cascade level"});
		_gui.addComboBox("shadowOptions", shadowOptions, {label:"Filter method"});
		_gui.addComboBox("depthMapSize", depthMapSize, {label:"Depth map size"});
		
		
		_gui.addColumn("Light Position");
		_gui.addSlider("lightDirection", 0, 360, {label:"Direction", tick:0.1});
		_gui.addSlider("lightElevation", 0, 90, {label:"Elevation", tick:0.1});
		_gui.show();*/
	}
		
	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		onResize();
	}
	
	/**
	 * Updates the mateiral mode between single pass and multi pass
	 */
	private function updateMaterialPass(materialDictionary:Map<String, Dynamic>):Void
	{
		var mesh:Mesh;
		var name:String;
		for (mesh in _meshes) {
			if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
				continue;
			name = mesh.material.name;
			var textureIndex:Int = _materialNameStrings.indexOf(name);
			if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
				continue;
			
			mesh.material = materialDictionary[name];
		}
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
	
	/**
	 * Count the total number of textures to be loaded
	 */
	private function countNumTextures():Void
	{
		_numTextures++;
		
		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] != null)
				break;
		
		//switch to next teture set
		if (_n < _loadingTextureStrings.length) {
			countNumTextures();
		} else if (_loadingTextureStrings == _diffuseTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			countNumTextures();
		} else if (_loadingTextureStrings == _normalTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			countNumTextures();
		}
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
				url = "sponza/" + url;
			case "atf": 
				_currentTexture++;
				_loadingText = "Loading Textures";
                loader.addEventListener(Event.COMPLETE, onATFComplete);
				url = "sponza/atf/" + url;
        }
		
        loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
		var urlReq:URLRequest = new URLRequest(_assetsRoot+url);
		loader.load(urlReq);
		
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
	 * Parses the ATF file
	 */
	private function onATFComplete(e:Event):Void
	{
        var loader:URLLoader = cast e.target;
        loader.removeEventListener(Event.COMPLETE, onATFComplete);
		
		if (!_textureDictionary[_loadingTextureStrings[_n]])
		{
			_textureDictionary[_loadingTextureStrings[_n]] = new ATFTexture(loader.data);
		}
			
        loader.data = null;
        loader.close();
		loader = null;
		
		
		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] != null)
				break;
		
		//switch to next teture set
        if (_n < _loadingTextureStrings.length) {
            load(_loadingTextureStrings[_n]);
		} else if (_loadingTextureStrings == _diffuseTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			load(_loadingTextureStrings[_n]);
		} else if (_loadingTextureStrings == _normalTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			load(_loadingTextureStrings[_n]);
		} else {
        	load("sponza/sponza.awd");
        }
    }
	
	
	/**
	 * Parses the Bitmap file
	 */
    private function parseBitmap(e:Event):Void 
	{
        var urlLoader:URLLoader = cast e.target;
        var loader:Loader = new Loader();
        loader.loadBytes(urlLoader.data);
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
        urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
        urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
        loader = null;
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
		if (!_textureDictionary[_loadingTextureStrings[_n]])
        	_textureDictionary[_loadingTextureStrings[_n]] = (_loadingTextureStrings == _specularTextureStrings)? new SpecularBitmapTexture(cast(loaderInfo.content, Bitmap).bitmapData) : Cast.bitmapTexture(loaderInfo.content);
			
        loader.unload();
        loader = null;
		
		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] != null)
				break;
		
		//switch to next teture set
        if (_n < _loadingTextureStrings.length) {
            load(_loadingTextureStrings[_n]);
		} else if (_loadingTextureStrings == _diffuseTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			load(_loadingTextureStrings[_n]);
		} else if (_loadingTextureStrings == _normalTextureStrings) {
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			load(_loadingTextureStrings[_n]);
		} else {
        	load("sponza/sponza.awd");
        }
    }
	
    /**
     * Parses the AWD file
     */
    private function parseAWD(e:Event):Void
	{
		log("Parsing Data");
        var loader:URLLoader = cast e.target;
        var loader3d:Loader3D = new Loader3D(false);
		var context:AssetLoaderContext = new AssetLoaderContext();
		//context.includeDependencies = false;
		context.dependencyBaseUrl = "assets/sponza/";
        loader3d.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
        loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete, false, 0, true);
        loader3d.loadData(loader.data, context, null, new AWDParser());
		
        loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
        loader.removeEventListener(Event.COMPLETE, parseAWD);
        loader = null;
    }
    
    /**
     * Listener function for asset complete event on loader
     */
    private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.MESH) {
			//store meshes
			_meshes.push(cast(event.asset, Mesh));
		}
	}
	
	/**
     * Triggered once all resources are loaded
     */
    private function onResourceComplete(e:LoaderEvent):Void
	{
		var merge:Merge = new Merge(false, false, true);
		
		_text.visible = false;
		
        var loader3d:Loader3D = cast e.target;
        loader3d.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
        loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		
		//reassign materials
		var mesh:Mesh;
		var name:String;
		
		for (mesh in _meshes) {
			if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
				continue;
			
			var num:Float = Std.parseFloat(mesh.name.substring(7));
			
			name = mesh.material.name;
			
			if (name == "column_c" && (num < 22 || num > 33))
				continue;
			
			var colNum:Float = (num - 125);
			if (name == "column_b") {
				if (colNum  >=0 && colNum < 132 && (colNum % 11) < 10) {
					colMeshes.push(mesh);
					continue;
				} else {
					colMeshes.push(mesh);
					var colMerge:Merge = new Merge();
					var colMesh:Mesh = new Mesh(new Geometry());
					colMerge.applyToMeshes(colMesh, colMeshes);
					mesh = colMesh;
					colMeshes = new Vector<Mesh>();
				}
			}
			
			var vaseNum:Float = (num - 334);
			if (name == "vase_hanging" && (vaseNum % 9) < 5) {
				if (vaseNum  >=0 && vaseNum < 370 && (vaseNum % 9) < 4) {
					vaseMeshes.push(mesh);
					continue;
				} else {
					vaseMeshes.push(mesh);
					var vaseMerge:Merge = new Merge();
					var vaseMesh:Mesh = new Mesh(new Geometry());
					vaseMerge.applyToMeshes(vaseMesh, vaseMeshes);
					mesh = vaseMesh;
					vaseMeshes = new Vector<Mesh>();
				}
			}
			
			var poleNum:Float = num - 290;
			if (name == "flagpole") {
				if (poleNum >=0 && poleNum < 320 && (poleNum % 3) < 2) {
					poleMeshes.push(mesh);
					continue;
				} else if (poleNum >=0) {
					poleMeshes.push(mesh);
					var poleMerge:Merge = new Merge();
					var poleMesh:Mesh = new Mesh(new Geometry());
					poleMerge.applyToMeshes(poleMesh, poleMeshes);
					mesh = poleMesh;
					poleMeshes = new Vector<Mesh>();
				}
			}
			
			if (name == "flagpole" && (num == 260 || num == 261 || num == 263 || num == 265 || num == 268 || num == 269 || num == 271 || num == 273))
				continue;
			
			var textureIndex:Int = _materialNameStrings.indexOf(name);
			if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
				continue;
			
			_numTexStrings[textureIndex] += 1;
			
			var textureName:String = _diffuseTextureStrings[textureIndex];
			var normalTextureName:String;
			var specularTextureName:String;
			
			//store single pass materials for use later
			var singleMaterial:TextureMaterial = _singleMaterialDictionary[name];
			
			if (singleMaterial == null) {
				
				//create singlepass material
				singleMaterial = new TextureMaterial(_textureDictionary[textureName]);
				
				singleMaterial.name = name;
				singleMaterial.lightPicker = _lightPicker;
				singleMaterial.addMethod(_fogMethod);
				singleMaterial.mipmap = true;
				singleMaterial.repeat = true;
				singleMaterial.specular = 2;
				
				//use alpha transparancy if texture is png
				if (textureName.substring(textureName.length - 3) == "png")
					singleMaterial.alphaThreshold = 0.5;
				
				//add normal map if it exists
				normalTextureName = _normalTextureStrings[textureIndex];
				if (normalTextureName != null)
					singleMaterial.normalMap = _textureDictionary[normalTextureName];
				
				//add specular map if it exists
				specularTextureName = _specularTextureStrings[textureIndex];
				if (specularTextureName != null)
					singleMaterial.specularMap = _textureDictionary[specularTextureName];
				
				_singleMaterialDictionary[name] = singleMaterial;
				
			}

			//store multi pass materials for use later
			var multiMaterial:TextureMultiPassMaterial = _multiMaterialDictionary[name];
			
			if (multiMaterial == null) {
				
				//create multipass material
				multiMaterial = new TextureMultiPassMaterial(_textureDictionary[textureName]);
				multiMaterial.name = name;
				multiMaterial.lightPicker = _lightPicker;
				multiMaterial.shadowMethod = _cascadeMethod;
				multiMaterial.addMethod(_fogMethod);
				multiMaterial.mipmap = true;
				multiMaterial.repeat = true;
				multiMaterial.specular = 2;
				
				
				//use alpha transparancy if texture is png
				if (textureName.substring(textureName.length - 3) == "png")
					multiMaterial.alphaThreshold = 0.5;
				
				//add normal map if it exists
				normalTextureName = _normalTextureStrings[textureIndex];
				if (normalTextureName != null)
					multiMaterial.normalMap = _textureDictionary[normalTextureName];
				
				//add specular map if it exists
				specularTextureName = _specularTextureStrings[textureIndex];
				if (specularTextureName != null)
					multiMaterial.specularMap = _textureDictionary[specularTextureName];
				
				//add to material dictionary
				_multiMaterialDictionary[name] = multiMaterial;
			}
			/*
			if (_meshReference[textureIndex]) {
				var m:Mesh = mesh.clone() as Mesh;
				m.material = multiMaterial;
				_view.scene.addChild(m);
				continue;
			}
			*/
			//default to multipass material
			mesh.material = multiMaterial;
			
			_view.scene.addChild(mesh);
			
			_meshReference[textureIndex] = mesh;
		}
		
		var z:Int = 0;
		
		while (z < _numTexStrings.length)
		{
			trace(_diffuseTextureStrings[z], _numTexStrings[z]);
			z++;
		}
		
		initMaterials();
		initObjects();
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
		
		if (_walkSpeed != 0 || _walkAcceleration != 0) {
			_walkSpeed = (_walkSpeed + _walkAcceleration)*_drag;
			if (Math.abs(_walkSpeed) < 0.01)
				_walkSpeed = 0;
			_cameraController.incrementWalk(_walkSpeed);
		}
		
		if (_strafeSpeed != 0 || _strafeAcceleration != 0) {
			_strafeSpeed = (_strafeSpeed + _strafeAcceleration)*_drag;
			if (Math.abs(_strafeSpeed) < 0.01)
				_strafeSpeed = 0;
			_cameraController.incrementStrafe(_strafeSpeed);
		}
		
		//animate flames
		for (flameVO in _flameData) {
			//update flame light
			var light : PointLight = flameVO.light;
			
			if (light == null)
				continue;
			
			light.fallOff = 380+Math.random()*20;
			light.radius = 200+Math.random()*30;
			light.diffuse = .9+Math.random()*.1;
			
			//update flame mesh
			var mesh : Mesh = flameVO.mesh;
			
			if (mesh == null)
				continue;
			
			var subMesh : SubMesh = mesh.subMeshes[0];
			subMesh.offsetU += 1/16;
			subMesh.offsetU %= 1;
			mesh.rotationY = Math.atan2(mesh.x - _view.camera.x, mesh.z - _view.camera.z)*180/Math.PI;
		}
		
		_view.render();
		
	}
	
			
	/**
	 * Key down listener for camera control
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W:
				_walkAcceleration = _walkIncrement;
			case Keyboard.DOWN, Keyboard.S:
				_walkAcceleration = -_walkIncrement;
			case Keyboard.LEFT, Keyboard.A:
				_strafeAcceleration = -_strafeIncrement;
			case Keyboard.RIGHT, Keyboard.D:
				_strafeAcceleration = _strafeIncrement;
			case Keyboard.F:
				stage.displayState = StageDisplayState.FULL_SCREEN;
			case Keyboard.C:
				_cameraController.fly = !_cameraController.fly;
		}
	}
	
	/**
	 * Key up listener for camera control
	 */
	private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.DOWN, Keyboard.S:
				_walkAcceleration = 0;
			case Keyboard.LEFT, Keyboard.A, Keyboard.RIGHT, Keyboard.D:
				_strafeAcceleration = 0;
		}
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent):Void
	{
		_move = true;
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
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
	
    /**
     * log for display info
     */
    private function log(t:String):Void
	{
        _text.htmlText = t;
		_text.visible = true;
    }
}

/**
* Data class for the Flame objects
*/
private class FlameVO
{
	public var position : Vector3D;
	public var color : Int;
	public var mesh : Mesh;
	public var light : PointLight;
	
	public function new(position : Vector3D, color : Int)
	{
		this.position = position;
		this.color = color;
	}
}