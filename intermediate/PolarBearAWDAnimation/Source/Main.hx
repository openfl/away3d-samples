/*

Bones animation loading and interaction example in Away3d

Demonstrates:

How to load an AWD file with bones animation from external resources.
How to map animation data after loading in order to playback an animation sequence.
How to control the movement of a game character using the mouse.
How to use a skybox with a fog method to create a seamless play area.
How to create a snow effect with the particle system.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

Model by Billy Allison
bli@blimation.com
http://www.blimation.com/

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
import openfl.net.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.Vector;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.animators.transitions.*;
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
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.tools.helpers.*;
import away3d.tools.helpers.data.*;
import away3d.utils.*;

class Main extends Sprite
{
	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var cameraController:LookAtController;
	private var awayStats:AwayStats;
	
	//animation variables
	private var skeletonAnimator:SkeletonAnimator;
	private var skeletonAnimationSet:SkeletonAnimationSet;
	private var stateTransition:CrossfadeTransition = new CrossfadeTransition(0.5);
	private var isRunning:Bool;
	private var isMoving:Bool;
	private var movementDirection:Float;
	private var currentAnim:String;
	private var currentRotationInc:Float = 0;
	
	//animation constants
	private static inline var ANIM_BREATHE:String = "Breathe";
	private static inline var ANIM_WALK:String = "Walk";
	private static inline var ANIM_RUN:String = "Run";
	private static inline var ROTATION_SPEED:Float = 3;
	private static inline var RUN_SPEED:Float = 2;
	private static inline var WALK_SPEED:Float = 1;
	private static inline var BREATHE_SPEED:Float = 1;
	
	//light objects
	private var sunLight:DirectionalLight;
	private var skyLight:PointLight;
	private var lightPicker:StaticLightPicker;
	private var softShadowMapMethod:NearShadowMapMethod;
	private var fogMethod:FogMethod;
	
	//material objects
	private var bearMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;
	
	//scene objects
	private var text:TextField;
	private var polarBearMesh:Mesh;
	private var ground:Mesh;
	private var skyBox:SkyBox;
	private var particleMesh:Mesh;
	
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
		
		camera = new Camera3D();
		camera.lens.far = 5000;
		camera.lens.near = 20;
		camera.y = 500;
		camera.z = 0;
		camera.lookAt(new Vector3D(0, 0, 1000));
			
		view = new View3D();
		view.scene = scene;
		view.camera = camera;
		
		//setup controller to be used on the camera
		var placeHolder:ObjectContainer3D = new ObjectContainer3D();
		placeHolder.z = 1000;
		cameraController = new LookAtController(camera, placeHolder);
		
		addChild(view);
		
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
		text.text = "Cursor keys / WSAD - move\n"; 
		text.appendText("SHIFT - hold down to run\n");
		
		//text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		
		addChild(text);
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a light for shadows that mimics the sun's position in the skybox
		sunLight = new DirectionalLight(-1, -0.4, 1);
		sunLight.shadowMapper = new NearDirectionalShadowMapper(0.5);
		sunLight.color = 0xFFFFFF;
		sunLight.castsShadows = true;
		sunLight.ambient = 1;
		sunLight.diffuse = 1;
		sunLight.specular = 1;
		scene.addChild(sunLight);
		
		//create a light for ambient effect that mimics the sky
		skyLight = new PointLight();
		skyLight.y = 500;
		skyLight.color = 0xFFFFFF;
		skyLight.diffuse = 1;
		skyLight.specular = 0.5;
		skyLight.radius = 2000;
		skyLight.fallOff = 2500;
		scene.addChild(skyLight);
		
		lightPicker = new StaticLightPicker([sunLight, skyLight]);
		
		//create a global shadow method
		softShadowMapMethod = new NearShadowMapMethod(new SoftShadowMapMethod(sunLight, 10, 4));
		
		//create a global fog method
		fogMethod = new FogMethod(0, 3000, 0x5f5e6e);
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		Asset3DLibrary.enableParser(AWDParser);
		Asset3DLibrary.enableParser(OBJParser);
		
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.load(new URLRequest("assets/PolarBear.awd"));
		Asset3DLibrary.load(new URLRequest("assets/snow.obj"));
		
		//create a snowy ground plane
		groundMaterial = new TextureMaterial(Cast.bitmapTexture("assets/snow_diffuse.png"), true, true, true);
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.specularMap = Cast.bitmapTexture("assets/snow_specular.png");
		groundMaterial.normalMap = Cast.bitmapTexture("assets/snow_normals.png");
		groundMaterial.shadowMethod = softShadowMapMethod;
		groundMaterial.addMethod(fogMethod);
		groundMaterial.ambient = 0.5;
		ground = new Mesh(new PlaneGeometry(50000, 50000), groundMaterial);
		ground.geometry.scaleUV(50, 50);
		ground.castsShadows = true;
		scene.addChild(ground);
		
		//create a skybox
		cubeTexture = new BitmapCubeTexture(
			Cast.bitmapData("assets/skybox/sky_posX.jpg"), Cast.bitmapData("assets/skybox/sky_negX.jpg"),
			Cast.bitmapData("assets/skybox/sky_posY.jpg"), Cast.bitmapData("assets/skybox/sky_negY.jpg"),
			Cast.bitmapData("assets/skybox/sky_posZ.jpg"), Cast.bitmapData("assets/skybox/sky_negZ.jpg"));
		skyBox = new SkyBox(cubeTexture);
		scene.addChild(skyBox);
	}
	
	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		//update character animation
		if (polarBearMesh != null)
			polarBearMesh.rotationY += currentRotationInc;
		
		view.render();
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.SKELETON) {
			//create a new skeleton animation set
			skeletonAnimationSet = new SkeletonAnimationSet(3);
			
			//wrap our skeleton animation set in an animator object and add our sequence objects
			skeletonAnimator = new SkeletonAnimator(skeletonAnimationSet, cast event.asset, false);
			
			//apply our animator to our mesh
			polarBearMesh.animator = skeletonAnimator;
			
			//register our mesh as the lookAt target
			cameraController.lookAtObject = polarBearMesh;
			
			//add key listeners
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		} else if (event.asset.assetType == Asset3DType.ANIMATION_NODE) {
			//create animation objects for each animation node encountered
			var animationNode:SkeletonClipNode = cast event.asset;
			
			skeletonAnimationSet.addAnimation(animationNode);
			if (animationNode.name == ANIM_BREATHE)
				stop();
		} else if (event.asset.assetType == Asset3DType.MESH) {
			if (event.asset.name == "PolarBear") {
				//create material object and assign it to our mesh
				bearMaterial = new TextureMaterial(Cast.bitmapTexture("assets/polarbear_diffuse.jpg"));
				bearMaterial.shadowMethod = softShadowMapMethod;
				bearMaterial.normalMap = Cast.bitmapTexture("assets/polarbear_normals.jpg");
				bearMaterial.specularMap = Cast.bitmapTexture("assets/polarbear_specular.jpg");
				bearMaterial.addMethod(fogMethod);
				bearMaterial.lightPicker = lightPicker;
				bearMaterial.gloss = 50;
				bearMaterial.specular = 0.5;
				bearMaterial.ambientColor = 0xAAAAAA;
				bearMaterial.ambient = 0.5;
				
				//create mesh object and assign our animation object and material object
				polarBearMesh = cast event.asset;
				polarBearMesh.material = bearMaterial;
				polarBearMesh.castsShadows = true;
				polarBearMesh.scale(1.5);
				polarBearMesh.z = 1000;
				polarBearMesh.rotationY = -45;
				scene.addChild(polarBearMesh);
			} else {
				//create particle system and add it to our scene
				var geometry:Geometry = cast(event.asset, Mesh).geometry;
				var geometrySet:Vector<Geometry> = new Vector<Geometry>();
				var transforms:Vector<ParticleGeometryTransform> = new Vector<ParticleGeometryTransform>();
				var scale:Float;
				var vertexTransform:Matrix3D;
				var particleTransform:ParticleGeometryTransform;
				for (i in 0...3000)
				{
					geometrySet.push(geometry);
					particleTransform = new ParticleGeometryTransform();
					scale = Math.random()  + 1;
					vertexTransform = new Matrix3D();
					vertexTransform.appendScale(scale, scale, scale);
					particleTransform.vertexTransform = vertexTransform;
					transforms.push(particleTransform);
				}
				
				var particleGeometry:Geometry = ParticleGeometryHelper.generateGeometry(geometrySet,transforms);
				
				
				var particleAnimationSet:ParticleAnimationSet = new ParticleAnimationSet(true, true);
				particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.GLOBAL, new Vector3D(0, -100, 0)));
				particleAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.addAnimation(new ParticleOscillatorNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.addAnimation(new ParticleRotationalVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.initParticleFunc = initParticleFunc;
				
				var material:ColorMaterial = new ColorMaterial();
				material.lightPicker = lightPicker;
				particleMesh = new Mesh(particleGeometry, material);
				particleMesh.bounds.fromSphere(new Vector3D(), 2000);
				var particleAnimator:ParticleAnimator = new ParticleAnimator(particleAnimationSet);
				particleMesh.animator = particleAnimator;
				particleAnimator.start();
				particleAnimator.resetTime(-10000);
				scene.addChild(particleMesh);
			}
			
		}
	}
	
	private function initParticleFunc(param:ParticleProperties):Void
	{
		param.startTime = Math.random()*20 - 10;
		param.duration = 20;
		param.nodes[ParticleOscillatorNode.OSCILLATOR_VECTOR3D] = new Vector3D(Math.random() * 100 - 50, 0, Math.random() * 100 - 50, Math.random() * 2 + 3);
		param.nodes[ParticlePositionNode.POSITION_VECTOR3D] = new Vector3D(Math.random() * 10000 - 5000, 1200, Math.random() * 10000 - 5000);
		param.nodes[ParticleRotationalVelocityNode.ROTATIONALVELOCITY_VECTOR3D] = new Vector3D(Math.random(), Math.random(), Math.random(), Math.random() * 2 + 2);
	}
	
	/**
	 * Key down listener for animation
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.SHIFT:
				isRunning = true;
				if (isMoving)
					updateMovement(movementDirection);
			case Keyboard.UP, Keyboard.W:
				updateMovement(movementDirection = 1);
			case Keyboard.DOWN, Keyboard.S:
				updateMovement(movementDirection = -1);
			case Keyboard.LEFT, Keyboard.A:
				currentRotationInc = -ROTATION_SPEED;
			case Keyboard.RIGHT, Keyboard.D:
				currentRotationInc = ROTATION_SPEED;
		}
	}
	
	private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.SHIFT:
				isRunning = false;
				if (isMoving)
					updateMovement(movementDirection);
			case Keyboard.UP, Keyboard.W, Keyboard.DOWN, Keyboard.S:
				stop();
			case Keyboard.LEFT, Keyboard.A, Keyboard.RIGHT, Keyboard.D:
				currentRotationInc = 0;
		}
	}
	
	private function updateMovement(dir:Float):Void
	{
		isMoving = true;
		
		//update animator speed
		skeletonAnimator.playbackSpeed = dir*(isRunning? RUN_SPEED : WALK_SPEED);
		
		//update animator sequence
		var anim:String = isRunning? ANIM_RUN : ANIM_WALK;
		if (currentAnim == anim)
			return;
		
		currentAnim = anim;
		
		skeletonAnimator.play(currentAnim, stateTransition);
	}
	
	private function stop():Void
	{
		isMoving = false;
		
		//update animator speed
		skeletonAnimator.playbackSpeed = BREATHE_SPEED;
		
		//update animator sequence
		if (currentAnim == ANIM_BREATHE)
			return;
		
		currentAnim = ANIM_BREATHE;
		
		skeletonAnimator.play(currentAnim, stateTransition);
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