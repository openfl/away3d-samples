/*

Globe example in Away3d

Demonstrates:

How to create a textured sphere.
How to use containers to rotate an object.
How to use the PhongBitmapMaterial.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

The skybox is "Purple Nebula", created by David Bronke for the RFI MMORPG project.
https://github.com/SkewedAspect/rfi-content/tree/master/source/skybox/textures

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

import away3d.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.lights.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.compilation.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.utils.*;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.Assets;
import openfl.Vector;

class Main extends Sprite
{
	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var cameraController:HoverController;
	private var awayStats:AwayStats;
	
	//material objects
	private var sunMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var cloudMaterial:TextureMaterial;
	private var atmosphereMaterial:ColorMaterial;
	private var atmosphereDiffuseMethod:BasicDiffuseMethod;
	private var atmosphereSpecularMethod:BasicSpecularMethod;
	private var cubeTexture:BitmapCubeTexture;
	
	//scene objects
	private var sun:Sprite3D;
	private var earth:Mesh;
	private var clouds:Mesh;
	private var atmosphere:Mesh;
	private var tiltContainer:ObjectContainer3D;
	private var orbitContainer:ObjectContainer3D;
	private var skyBox:SkyBox;
	
	//light objects
	private var light:PointLight;
	private var lightPicker:StaticLightPicker;
	private var flares:Vector<FlareObject> = new Vector<FlareObject>();
	
	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var mouseLockX:Float = 0;
	private var mouseLockY:Float = 0;
	private var mouseLocked:Bool;
	private var flareVisible:Bool;
	
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
		initLensFlare();
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
		
		scene = new Scene3D();
		
		//setup camera for optimal skybox rendering
		camera = new Camera3D();
		camera.lens.far = 100000;
		
		view = new View3D();
		view.scene = scene;
		view.camera = camera;
		
		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 0, 0, 600, -90, 90);
		cameraController.yFactor = 1;
		
		//setup parser to be used on loader3D
		Parsers.enableAllBundled();
		
		addChild(view);
		
		addChild(awayStats = new AwayStats(view));
		
		stage.quality = StageQuality.BEST;
	}
	
	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		var text:TextField = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF);
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.ADVANCED;
		text.gridFitType = GridFitType.PIXEL;
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "MOUSE:\n" +
			"\t windowed: click and drag - rotate\n" + 
			"\t fullscreen: mouse move - rotate\n" + 
			"SCROLL_WHEEL - zoom\n" + 
			"SPACE - enables fullscreen mode";
		
		//text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		
		addChild(text);
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		light = new PointLight();
		light.x = 10000;
		light.ambient = 1;
		light.diffuse = 2;
		
		lightPicker = new StaticLightPicker([light]);
	}
	
	private function initLensFlare():Void
	{
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare10.jpg"),  3.2, -0.01, 147.9));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare11.jpg"),  6,    0,     30.6));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare7.jpg"),   2,    0,     25.5));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare7.jpg"),   4,    0,     17.85));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare12.jpg"),  0.4,  0.32,  22.95));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare6.jpg"),   1,    0.68,  20.4));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare2.jpg"),   1.25, 1.1,   48.45));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare3.jpg"),   1.75, 1.37,   7.65));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare4.jpg"),   2.75, 1.85,  12.75));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare8.jpg"),   0.5,  2.21,  33.15));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare6.jpg"),   4,    2.5,   10.4));
		flares.push(new FlareObject(Assets.getBitmapData("assets/lensflare/flare7.jpg"),   10,   2.66,  50));
	}
	
	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		cubeTexture = new BitmapCubeTexture(
			Cast.bitmapData("assets/skybox/space_posX.jpg"),
			Cast.bitmapData("assets/skybox/space_negX.jpg"),
			Cast.bitmapData("assets/skybox/space_posY.jpg"),
			Cast.bitmapData("assets/skybox/space_negY.jpg"),
			Cast.bitmapData("assets/skybox/space_posZ.jpg"),
			Cast.bitmapData("assets/skybox/space_negZ.jpg"));
		
		//adjust specular map
		var specBitmap:BitmapData = Cast.bitmapData("assets/globe/earth_specular_2048.jpg"); 
		specBitmap.colorTransform(specBitmap.rect, new ColorTransform(1, 1, 1, 1, 64, 64, 64));
		
		var specular:FresnelSpecularMethod = new FresnelSpecularMethod(true, new PhongSpecularMethod());
		specular.fresnelPower = 1;
		specular.normalReflectance = 0.1;
		
		sunMaterial = new TextureMaterial(Cast.bitmapTexture("assets/lensflare/flare10.jpg"));
		sunMaterial.blendMode = BlendMode.ADD;

		groundMaterial = new TextureMaterial(Cast.bitmapTexture("assets/globe/land_ocean_ice_2048_match.jpg"));
		groundMaterial.specularMethod = specular;
		groundMaterial.specularMap = new BitmapTexture(specBitmap);
		groundMaterial.normalMap = Cast.bitmapTexture("assets/globe/EarthNormal.png");
		groundMaterial.ambientTexture = Cast.bitmapTexture("assets/globe/land_lights_16384.jpg");
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.gloss = 5;
		groundMaterial.specular = 1;
		groundMaterial.ambientColor = 0xFFFFFF;
		groundMaterial.ambient = 1;

		var skyBitmap:BitmapData = new BitmapData(2048, 1024, true, 0xFFFFFFFF);
		skyBitmap.copyChannel(Cast.bitmapData("assets/globe/cloud_combined_2048.jpg"), skyBitmap.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		
		cloudMaterial = new TextureMaterial(new BitmapTexture(skyBitmap));
		cloudMaterial.alphaBlending = true;
		cloudMaterial.lightPicker = lightPicker;
		cloudMaterial.specular = 0;
		cloudMaterial.ambientColor = 0x1b2048;
		cloudMaterial.ambient = 1;
		
		atmosphereDiffuseMethod =  new CompositeDiffuseMethod(modulateDiffuseMethod);
		atmosphereSpecularMethod =  new CompositeSpecularMethod(modulateSpecularMethod, new PhongSpecularMethod());
		
		atmosphereMaterial = new ColorMaterial(0x1671cc);
		atmosphereMaterial.diffuseMethod = atmosphereDiffuseMethod;
		atmosphereMaterial.specularMethod = atmosphereSpecularMethod;
		atmosphereMaterial.blendMode = BlendMode.ADD;
		atmosphereMaterial.lightPicker = lightPicker;
		atmosphereMaterial.specular = 0.5;
		atmosphereMaterial.gloss = 5;
		atmosphereMaterial.ambientColor = 0x0;
		atmosphereMaterial.ambient = 1;
	}
	
	private function modulateDiffuseMethod(vo : MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
		var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;
		
		var code:String = "dp3 " + t + ".w, " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" + 
						"mul " + t + ".w, " + t + ".w, " + t + ".w\n";
		
		return code;
	}
	
	private function modulateSpecularMethod(vo : MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
		var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;
		var temp:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
		regCache.addFragmentTempUsages(temp, 1);
		
		var code:String = "dp3 " + temp + ", " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" + 
						"neg" + temp + ", " + temp + "\n" +
						"mul " + t + ".w, " + t + ".w, " + temp + "\n";
			
			regCache.removeFragmentTempUsage(temp);
		
		return code;
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		orbitContainer = new ObjectContainer3D();
		orbitContainer.addChild(light);
		scene.addChild(orbitContainer);
		
		sun = new Sprite3D(sunMaterial, 3000, 3000);
		sun.x = 10000;
		orbitContainer.addChild(sun);
		
		earth = new Mesh(new SphereGeometry(200, 200, 100), groundMaterial);
		
		clouds = new Mesh(new SphereGeometry(202, 200, 100), cloudMaterial);

		atmosphere = new Mesh(new SphereGeometry(210, 200, 100), atmosphereMaterial);
		atmosphere.scaleX = -1;

		tiltContainer = new ObjectContainer3D();
		tiltContainer.rotationX = -23;
		tiltContainer.addChild(earth);
		tiltContainer.addChild(clouds);
		tiltContainer.addChild(atmosphere);
		
		scene.addChild(tiltContainer);
		
		cameraController.lookAtObject = tiltContainer;
		
		//create a skybox
		skyBox = new SkyBox(cubeTexture);
		scene.addChild(skyBox);
	}
	
	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(e:Event):Void
	{
		earth.rotationY += 0.2;
		clouds.rotationY += 0.21;
		orbitContainer.rotationY += 0.02;
		
		//if (stage.mouseLock) {
			//cameraController.panAngle = 0.3*mouseLockX;
			//cameraController.tiltAngle = 0.3*mouseLockY;
		//} else
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		
		view.render();
		
		updateFlares();
	}
	
	private function updateFlares():Void
	{
		var flareVisibleOld:Bool = flareVisible;
		
		var sunScreenPosition:Vector3D = view.project(sun.scenePosition);
		var xOffset:Float = sunScreenPosition.x - stage.stageWidth/2;
		var yOffset:Float = sunScreenPosition.y - stage.stageHeight/2;
		
		var earthScreenPosition:Vector3D = view.project(earth.scenePosition);
		var earthRadius:Float = 190*stage.stageHeight/earthScreenPosition.z;
		var flareObject:FlareObject;
		
		flareVisible = (sunScreenPosition.x > 0 && sunScreenPosition.x < stage.stageWidth && sunScreenPosition.y > 0 && sunScreenPosition.y  < stage.stageHeight && sunScreenPosition.z > 0 && Math.sqrt(xOffset*xOffset + yOffset*yOffset) > earthRadius)? true : false;
		
		//update flare visibility
		if (flareVisible != flareVisibleOld) {
			for (flareObject in flares) {
				if (flareVisible)
					addChild(flareObject.sprite);
				else
					removeChild(flareObject.sprite);
			}
		}
		
		//update flare position
		if (flareVisible) {
			var flareDirection:Point = new Point(xOffset, yOffset);
			for (flareObject in flares) {
				flareObject.sprite.x = sunScreenPosition.x - flareDirection.x*flareObject.position - flareObject.sprite.width/2;
				flareObject.sprite.y = sunScreenPosition.y - flareDirection.y*flareObject.position - flareObject.sprite.height/2;
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
	private function onMouseUp(e:MouseEvent):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);    
	}
	
	/**
	 * Mouse move listener for mouseLock
	 */
	private function onMouseMove(e:MouseEvent):Void
	{
		/*
		if (stage.displayState == StageDisplayState.FULL_SCREEN) {
			
			if (mouseLocked && (lastMouseX != 0 || lastMouseY != 0)) {
				e.movementX += lastMouseX;
				e.movementY += lastMouseY;
				lastMouseX = 0;
				lastMouseY = 0;
			}
			
			mouseLockX += e.movementX;
			mouseLockY += e.movementY;
			
			if (!stage.mouseLock) {
				stage.mouseLock = true;
				lastMouseX = stage.mouseX - stage.stageWidth/2;
				lastMouseY = stage.mouseY - stage.stageHeight/2;
			} else if (!mouseLocked) {
				mouseLocked = true;
			}
			
			//ensure bounds for tiltAngle are not eceeded
			if (mouseLockY > cameraController.maxTiltAngle/0.3)
				mouseLockY = cameraController.maxTiltAngle/0.3;
			else if (mouseLockY < cameraController.minTiltAngle/0.3)
				mouseLockY = cameraController.minTiltAngle/0.3;
		}
		*/
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
	 * Mouse wheel listener for navigation
	 */
	private function onMouseWheel(event:MouseEvent) : Void
	{
		cameraController.distance -= event.delta*5;
		
		if (cameraController.distance < 400)
			cameraController.distance = 400;
		else if (cameraController.distance > 10000)
			cameraController.distance = 10000;
	}
	
	/**
	 * Key down listener for fullscreen
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.SPACE:
				if (stage.displayState == StageDisplayState.FULL_SCREEN) {
					stage.displayState = StageDisplayState.NORMAL;
				} else {
					stage.displayState = StageDisplayState.FULL_SCREEN;
					
					mouseLocked = false;
					mouseLockX = cameraController.panAngle/0.3;
					mouseLockY = cameraController.tiltAngle/0.3;
				}
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

class FlareObject
{
	private var flareSize:Int = 144;
	
	public var sprite:Bitmap;
	
	public var size:Float;
	
	public var position:Float;
	
	public var opacity:Float;
	
	/**
	 * Constructor
	 */
	public function new(bitmapData:BitmapData, size:Float, position:Float, opacity:Float)
	{
		this.sprite = new Bitmap(new BitmapData(bitmapData.width, bitmapData.height, true, 0xFFFFFFFF));
		this.sprite.bitmapData.copyChannel(bitmapData, bitmapData.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		this.sprite.alpha = opacity/100;
		this.sprite.smoothing = true;
		this.sprite.scaleX = this.sprite.scaleY = size*flareSize/bitmapData.width;
		this.size = size;
		this.position = position;
		this.opacity = opacity;
	}
}
