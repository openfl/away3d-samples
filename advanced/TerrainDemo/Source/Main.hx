/*

Terrain creation using height maps and splat maps

Demonstrates:

How to create a 3D terrain out of a hieght map
How to enhance the detail of a material close-up by applying splat maps.
How to create a realistic lake effect.
How to create first-person camera motion using the FirstPersonController.

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
import away3d.debug.*;
import away3d.entities.Mesh;
import away3d.extrusions.*;
import away3d.filters.BloomFilter3D;
import away3d.lights.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.utils.*;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.text.*;
import openfl.ui.*;

class Main extends Sprite
{
	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var cameraController:FirstPersonController;
	private var awayStats:AwayStats;
	
	//light objects
	private var sunLight:DirectionalLight;
	private var lightPicker:StaticLightPicker;
	private var fogMethod:FogMethod;
	
	//material objects
	private var terrainMethod:TerrainDiffuseMethod;
	private var waterMethod:SimpleWaterNormalMethod;
	private var fresnelMethod:FresnelSpecularMethod;
	private var terrainMaterial:TextureMaterial;
	private var waterMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;
	
	//scene objects
	private var text:TextField;
	private var terrain:Elevation;
	private var plane:Mesh;
	
	//rotation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	
	//movement variables
	private var drag:Float = 0.5;
	private var walkIncrement:Float = 2;
	private var strafeIncrement:Float = 2;
	private var walkSpeed:Float = 0;
	private var strafeSpeed:Float = 0;
	private var walkAcceleration:Float = 0;
	private var strafeAcceleration:Float = 0;
	
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

		view = new View3D();
		scene = view.scene;
		camera = view.camera;
		
		camera.lens.far = 4000;
		camera.lens.near = 1;
		camera.y = 300;

		//setup controller to be used on the camera
		cameraController = new FirstPersonController(camera, 180, 0, -80, 80);
		
		addChild(view);

		view.filters3d = [ new BloomFilter3D(200, 200, .85, 15, 2) ];

		awayStats = new AwayStats(view);
		addChild(awayStats);
	}
	
	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF);
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Mouse click and drag - rotate\n" + 
			"Cursor keys / WSAD - move\n";
		
		//text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		
		addChild(text);
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		sunLight = new DirectionalLight(-300, -300, -5000);
		sunLight.color = 0xfffdc5;
		sunLight.ambient = 1;
		scene.addChild(sunLight);
		
		lightPicker = new StaticLightPicker([sunLight]);
		
		//create a global fog method
		fogMethod = new FogMethod(0, 8000, 0xcfd9de);
	}
	
	/**
	 * Initialise the material
	 */
	private function initMaterials():Void
	{
		cubeTexture = new BitmapCubeTexture(
			Cast.bitmapData("assets/skybox/snow_positive_x.jpg"), Cast.bitmapData("assets/skybox/snow_negative_x.jpg"),
			Cast.bitmapData("assets/skybox/snow_positive_y.jpg"), Cast.bitmapData("assets/skybox/snow_negative_y.jpg"),
			Cast.bitmapData("assets/skybox/snow_positive_z.jpg"), Cast.bitmapData("assets/skybox/snow_negative_z.jpg"));

		terrainMethod = new TerrainDiffuseMethod([Cast.bitmapTexture("assets/terrain/beach.jpg"), Cast.bitmapTexture("assets/terrain/grass.jpg"), Cast.bitmapTexture("assets/terrain/rock.jpg")], Cast.bitmapTexture("assets/terrain/terrain_splats.png"), [1, 50, 150, 100]);

		terrainMaterial = new TextureMaterial(Cast.bitmapTexture("assets/terrain/terrain_diffuse.jpg"));
		terrainMaterial.diffuseMethod = terrainMethod;
		terrainMaterial.normalMap = Cast.bitmapTexture("assets/terrain/terrain_normals.jpg");
		terrainMaterial.lightPicker = lightPicker;
		terrainMaterial.ambientColor = 0x303040;
		terrainMaterial.ambient = 1;
		terrainMaterial.specular = .2;
		terrainMaterial.addMethod(fogMethod);
		
		waterMethod = new SimpleWaterNormalMethod(Cast.bitmapTexture("assets/water_normals.jpg"), Cast.bitmapTexture("assets/water_normals.jpg"));
		fresnelMethod = new FresnelSpecularMethod();
		fresnelMethod.normalReflectance = .3;
		
		waterMaterial = new TextureMaterial(new BitmapTexture(new BitmapData(512, 512, true, 0xaa404070)));
		waterMaterial.alphaBlending = true;
		waterMaterial.lightPicker = lightPicker;
		waterMaterial.repeat = true;
		waterMaterial.normalMethod = waterMethod;
		waterMaterial.addMethod(new EnvMapMethod(cubeTexture));
		waterMaterial.specularMethod = fresnelMethod;
		waterMaterial.gloss = 100;
		waterMaterial.specular = 1;
	}

	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create skybox.
		scene.addChild(new SkyBox(cubeTexture));

		//create mountain like terrain
		terrain = new Elevation(terrainMaterial, Cast.bitmapData("assets/terrain/terrain_heights.jpg"), 5000, 1300, 5000, 250, 250);
		scene.addChild(terrain);
		
		//create water
		plane = new Mesh(new PlaneGeometry(5000, 5000), waterMaterial);
		plane.geometry.scaleUV(50, 50);
		plane.y = 285;
		scene.addChild(plane);
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
		//set the camera height based on the terrain (with smoothing)
		camera.y += 0.2*(terrain.getHeightAt(camera.x, camera.z) + 20 - camera.y);
		
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			
		}
		
		if (walkSpeed != 0 || walkAcceleration != 0) {
			walkSpeed = (walkSpeed + walkAcceleration)*drag;
			if (Math.abs(walkSpeed) < 0.01)
				walkSpeed = 0;
			cameraController.incrementWalk(walkSpeed);
		}
		
		if (strafeSpeed != 0 || strafeAcceleration != 0) {
			strafeSpeed = (strafeSpeed + strafeAcceleration)*drag;
			if (Math.abs(strafeSpeed) < 0.01)
				strafeSpeed = 0;
			cameraController.incrementStrafe(strafeSpeed);
		}
		
		//animate our lake material
		waterMethod.water1OffsetX += .005;
		waterMethod.water1OffsetY += .007;
		waterMethod.water2OffsetX += .003;
		waterMethod.water2OffsetY += .004;
		
		view.render();
	}
	
	/**
	 * Key down listener for camera control
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W:
				walkAcceleration = walkIncrement;
			case Keyboard.DOWN, Keyboard.S:
				walkAcceleration = -walkIncrement;
			case Keyboard.LEFT, Keyboard.A:
				strafeAcceleration = -strafeIncrement;
			case Keyboard.RIGHT, Keyboard.D:
				strafeAcceleration = strafeIncrement;
		}
	}
	
	/**
	 * Key up listener for camera control
	 */
	private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.DOWN, Keyboard.S:
				walkAcceleration = 0;
			case Keyboard.LEFT, Keyboard.A, Keyboard.RIGHT, Keyboard.D:
				strafeAcceleration = 0;
		}
	}
	
	/**
	 * Mouse down listener for navigation
	 */
	private function onMouseDown(event:MouseEvent):Void
	{
		move = true;
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
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
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
		awayStats.x = stage.stageWidth - awayStats.width;
	}
}