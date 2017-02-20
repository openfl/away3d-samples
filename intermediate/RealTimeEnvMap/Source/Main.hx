/*

Real time environment map reflections

Demonstrates:

How to use the CubeReflectionTexture to dynamically render environment maps.
How to use EnvMapMethod to apply the dynamic environment map to a material.
How to use the Elevation extrusions class to create a terrain from a heightmap.

Code by David Lenaerts & Rob Bateman
david.lenaerts@gmail.com
http://www.derschmale.com
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

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

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.Assets;

import away3d.containers.*;
import away3d.controllers.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.extrusions.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.utils.*;

class Main extends Sprite
{
	//constants for R2D2 movement
	public static inline var MAX_SPEED : Float = 1;
	public static inline var MAX_ROTATION_SPEED : Float = 10;
	public static inline var DRAG : Float = .95;
	public static inline var ACCELERATION : Float = .5;
	public static inline var ROTATION : Float = .5;
	
	//engine variables
	private var view:View3D;
	private var cameraController:HoverController;
	private var awayStats:AwayStats;
	
	//material objects
	private var skyboxTexture : BitmapCubeTexture;
	private var reflectionTexture:CubeReflectionTexture;
	//private var floorMaterial : TextureMaterial;
	private var desertMaterial : TextureMaterial;
	private var reflectiveMaterial : ColorMaterial;
	private var r2d2Material : TextureMaterial;
	private var lightPicker : StaticLightPicker;
	private var fogMethod : FogMethod;
	
	//scene objects
	private var light:DirectionalLight;
	private var head:Mesh;
	private var r2d2:Mesh;
	
	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	
	//R2D2 motion variables
	//private var _drag : Float = 0.95;
	private var _acceleration : Float = 0;
	//private var _rotationDrag : Float = 0.95;
	private var _rotationAccel : Float = 0;
	private var _speed : Float = 0;
	private var _rotationSpeed : Float = 0;
	
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
		initReflectionCube();
		initMaterials();
		initObjects();
		initListeners();
	}
	
	/**
	 * Initialise the engine
	 */
	private function initEngine():Void
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		//setup view
		view = new View3D();
		view.camera.lens.far = 4000;
		
		addChild(view);

		//setup controller to be used on the camera
		cameraController = new HoverController(view.camera, null, 90, 10, 600, 2, 90);
		cameraController.lookAtPosition = new Vector3D(0, 120, 0);
		cameraController.wrapPanAngle = true;

		addChild(awayStats = new AwayStats(view));
	}

	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		var text : TextField = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF);
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.ADVANCED;
		text.gridFitType = GridFitType.PIXEL;
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Cursor keys / WSAD - Move R2D2\n";
		text.appendText("Click+drag: Move camera\n");
		//text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights in a scene
	 */
	private function initLights():Void
	{
		//create global light
		light = new DirectionalLight(-1, -2, 1);
		light.color = 0xeedddd;
		light.ambient = 1;
		light.ambientColor = 0x808090;
		view.scene.addChild(light);
		
		//create global lightpicker
		lightPicker = new StaticLightPicker([light]);
		
		//create global fog method
		fogMethod = new FogMethod(500, 2000, 0x5f5e6e);
	}

	/**
	 * Initialized the ReflectionCubeTexture that will contain the environment map render
	 */
	private function initReflectionCube() : Void
	{
	}


	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		// create reflection texture with a dimension of 256x256x256
		reflectionTexture = new CubeReflectionTexture(256);
		reflectionTexture.farPlaneDistance = 3000;
		reflectionTexture.nearPlaneDistance = 50;
		
		// center the reflection at (0, 100, 0) where our reflective object will be
		reflectionTexture.position = new Vector3D(0, 100, 0);
		
		//setup the skybox texture
		skyboxTexture = new BitmapCubeTexture(
			Cast.bitmapData("assets/skybox/sky_posX.jpg"), Cast.bitmapData("assets/skybox/sky_negX.jpg"),
			Cast.bitmapData("assets/skybox/sky_posY.jpg"), Cast.bitmapData("assets/skybox/sky_negY.jpg"),
			Cast.bitmapData("assets/skybox/sky_posZ.jpg"), Cast.bitmapData("assets/skybox/sky_negZ.jpg")
		);
		
		// setup desert floor material
		desertMaterial = new TextureMaterial(Cast.bitmapTexture("assets/arid.jpg"));
		desertMaterial.lightPicker = lightPicker;
		desertMaterial.addMethod(fogMethod);
		desertMaterial.repeat = true;
		desertMaterial.gloss = 5;
		desertMaterial.specular = .1;
		
		//setup R2D2 material
		r2d2Material = new TextureMaterial(Cast.bitmapTexture("assets/r2d2_diffuse.jpg"));
		r2d2Material.lightPicker = lightPicker;
		r2d2Material.addMethod(fogMethod);
		r2d2Material.addMethod(new EnvMapMethod(skyboxTexture,.2));

		// setup fresnel method using our reflective texture in the place of a static environment map
		var fresnelMethod : FresnelEnvMapMethod = new FresnelEnvMapMethod(reflectionTexture);
		fresnelMethod.normalReflectance = .6;
		fresnelMethod.fresnelPower = 2;
		
		//setup the reflective material
		reflectiveMaterial = new ColorMaterial(0x000000);
		reflectiveMaterial.addMethod(fresnelMethod);
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create the skybox
		view.scene.addChild(new SkyBox(skyboxTexture));
		
		//create the desert ground
		var desert:Elevation = new Elevation(desertMaterial, Cast.bitmapData("assets/desertHeightMap.jpg"), 5000, 300, 5000, 250, 250);
		desert.y = -3;
		desert.geometry.scaleUV(25, 25);
		view.scene.addChild(desert);
		
		//enabled the obj parser
		Asset3DLibrary.enableParser(OBJParser);
		
		// load model data
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.loadData(Assets.getBytes("assets/head.obj"));
		Asset3DLibrary.loadData(Assets.getBytes("assets/R2D2.obj"));
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
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		
		if (r2d2 != null) {
			//drag
			_speed *= DRAG;
			
			//acceleration
			_speed += _acceleration;
			
			//speed bounds
			if (_speed > MAX_SPEED)
				_speed = MAX_SPEED;
			else if (_speed < -MAX_SPEED)
				_speed = -MAX_SPEED;
			
			//rotational drag
			_rotationSpeed *= DRAG;
			
			//rotational acceleration
			_rotationSpeed += _rotationAccel;
			
			//rotational speed bounds
			if (_rotationSpeed > MAX_ROTATION_SPEED)
				_rotationSpeed = MAX_ROTATION_SPEED;
			else if (_rotationSpeed < -MAX_ROTATION_SPEED)
				_rotationSpeed = -MAX_ROTATION_SPEED;
			
			//apply motion to R2D2
			r2d2.moveForward(_speed);
			r2d2.rotationY += _rotationSpeed;
			
			//keep R2D2 within max and min radius
			var radius:Float = Math.sqrt(r2d2.x*r2d2.x + r2d2.z*r2d2.z);
			if (radius < 200) {
				r2d2.x = 200*r2d2.x/radius;
				r2d2.z = 200*r2d2.z/radius;
			} else if (radius > 500) {
				r2d2.x = 500*r2d2.x/radius;
				r2d2.z = 500*r2d2.z/radius;
			}
			
			//pan angle overridden by R2D2 position
			cameraController.panAngle = 90 - 180*Math.atan2(r2d2.z, r2d2.x)/Math.PI;
		}

		// render the view's scene to the reflection texture (view is required to use the correct stage3DProxy)
		reflectionTexture.render(view);
		view.render();
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.MESH) {
			if( event.asset.name == "g0" ) { // Head
				head = cast event.asset;
				head.scale(60);
				head.y = 180;
				head.rotationY = -90;
				head.material = reflectiveMaterial;
				view.scene.addChild(head);
			}
			else { // R2D2
				r2d2 = cast event.asset;
				r2d2.scale( 5 );
				r2d2.material = r2d2Material;
				r2d2.x = 200;
				r2d2.y = 30;
				r2d2.z = 0;
				view.scene.addChild(r2d2);
			}
		}
	}

	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent):Void
	{
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
		move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse up listener for navigation
	 */
	private function onMouseUp(event:MouseEvent):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
	
	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Listener for keyboard down events
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch(event.keyCode) {
			case Keyboard.W, Keyboard.UP:
				_acceleration = ACCELERATION;
			case Keyboard.S, Keyboard.DOWN:
				_acceleration = -ACCELERATION;
			case Keyboard.A, Keyboard.LEFT:
				_rotationAccel = -ROTATION;
			case Keyboard.D, Keyboard.RIGHT:
				_rotationAccel = ROTATION;
		}
	}

	/**
	 * Listener for keyboard up events
	 */
	private function onKeyUp(event:KeyboardEvent):Void
	{
		switch(event.keyCode) {
			case Keyboard.W, Keyboard.S, Keyboard.UP, Keyboard.DOWN:
				_acceleration = 0;
			case Keyboard.A, Keyboard.D, Keyboard.LEFT, Keyboard.RIGHT:
				_rotationAccel = 0;
		}
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
		awayStats.x = stage.stageWidth - awayStats.width;
	}
}