/*

MD5 animation loading and interaction example in Away3d

Demonstrates:

How to load MD5 mesh and anim files with bones animation from embedded resources.
How to map animation data after loading in order to playback an animation sequence.
How to control the movement of a game character using keys.

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

import away3d.animators.nodes.SkeletonClipNode;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.transitions.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
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
import away3d.utils.*;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.ByteArray;
import openfl.Assets;
import openfl.Vector;

class Main extends Sprite
{
	//hellknight mesh
	private static var HellKnight_Mesh:ByteArray;

	//hellknight animations
	private var HellKnight_Idle2:ByteArray;
	private var HellKnight_Walk7:ByteArray;
	private var HellKnight_Attack3:ByteArray;
	private var HellKnight_TurretAttack:ByteArray;
	private var HellKnight_Attack2:ByteArray;
	private var HellKnight_Chest:ByteArray;
	private var HellKnight_Roar1:ByteArray;
	private var HellKnight_LeftSlash:ByteArray;
	private var HellKnight_HeadPain:ByteArray;
	private var HellKnight_Pain1:ByteArray;
	private var HellKnight_PainLUPArm:ByteArray;
	private var HellKnight_RangeAttack2:ByteArray;

	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var cameraController:LookAtController;
	private var awayStats:AwayStats;

	//animation variables
	private var animator:SkeletonAnimator;
	private var animationSet:SkeletonAnimationSet;
	private var stateTransition:CrossfadeTransition = new CrossfadeTransition(0.5);
	private var skeleton:Skeleton;
	private var isRunning:Bool;
	private var isMoving:Bool;
	private var movementDirection:Float;
	private var onceAnim:String;
	private var currentAnim:String;
	private var currentRotationInc:Float = 0;

	//animation constants
	private static var IDLE_NAME:String = "idle2";
	private static var WALK_NAME:String = "walk7";
	private static var ANIM_NAMES:Array<String> = [IDLE_NAME, WALK_NAME, "attack3", "turret_attack", "attack2", "chest", "roar1", "leftslash", "headpain", "pain1", "pain_luparm", "range_attack2"];
	private static var ANIM_CLASSES:Array<ByteArray>;
	private static var ROTATION_SPEED:Float = 3;
	private static var RUN_SPEED:Float = 2;
	private static var WALK_SPEED:Float = 1;
	private static var IDLE_SPEED:Float = 1;
	private static var ACTION_SPEED:Float = 1;

	//light objects
	private var redLight:PointLight;
	private var blueLight:PointLight;
	private var whiteLight:DirectionalLight;
	private var lightPicker:StaticLightPicker;
	private var shadowMapMethod:NearShadowMapMethod;
	private var fogMethod:FogMethod;
	private var count:Float = 0;

	//material objects
	private var redLightMaterial:TextureMaterial;
	private var blueLightMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var bodyMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;

	//scene objects
	private var text:TextField;
	private var placeHolder:ObjectContainer3D;
	private var mesh:Mesh;
	private var ground:Mesh;
	private var skyBox:SkyBox;

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
		HellKnight_Mesh = Assets.getBytes("assets/hellknight/hellknight.md5mesh");
		
		HellKnight_Idle2 = Assets.getBytes("assets/hellknight/idle2.md5anim");
		HellKnight_Walk7 = Assets.getBytes("assets/hellknight/walk7.md5anim");
		HellKnight_Attack3 = Assets.getBytes("assets/hellknight/attack3.md5anim");
		HellKnight_TurretAttack = Assets.getBytes("assets/hellknight/turret_attack.md5anim");
		HellKnight_Attack2 = Assets.getBytes("assets/hellknight/attack2.md5anim");
		HellKnight_Chest = Assets.getBytes("assets/hellknight/chest.md5anim");
		HellKnight_Roar1 = Assets.getBytes("assets/hellknight/roar1.md5anim");
		HellKnight_LeftSlash = Assets.getBytes("assets/hellknight/leftslash.md5anim");
		HellKnight_HeadPain = Assets.getBytes("assets/hellknight/headpain.md5anim");
		HellKnight_Pain1 = Assets.getBytes("assets/hellknight/pain1.md5anim");
		HellKnight_PainLUPArm = Assets.getBytes("assets/hellknight/pain_luparm.md5anim");
		HellKnight_RangeAttack2 = Assets.getBytes("assets/hellknight/range_attack2.md5anim");
		
		ANIM_CLASSES = [HellKnight_Idle2, HellKnight_Walk7, HellKnight_Attack3, HellKnight_TurretAttack, HellKnight_Attack2, HellKnight_Chest, HellKnight_Roar1, HellKnight_LeftSlash, HellKnight_HeadPain, HellKnight_Pain1, HellKnight_PainLUPArm, HellKnight_RangeAttack2];
		
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

		camera.lens.far = 5000;
		camera.z = -200;
		camera.y = 160;

		//setup controller to be used on the camera
		placeHolder = new ObjectContainer3D();
		placeHolder.y = 50;
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
		text.appendText("Floats 1-9 - Attack\n");
		//text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a light for shadows that mimics the sun's position in the skybox
		redLight = new PointLight();
		redLight.x = -1000;
		redLight.y = 200;
		redLight.z = -1400;
		redLight.color = 0xff1111;
		scene.addChild(redLight);

		blueLight = new PointLight();
		blueLight.x = 1000;
		blueLight.y = 200;
		blueLight.z = 1400;
		blueLight.color = 0x1111ff;
		scene.addChild(blueLight);

		whiteLight = new DirectionalLight(-50, -20, 10);
		whiteLight.color = 0xffffee;
		whiteLight.castsShadows = true;
		whiteLight.ambient = 1;
		whiteLight.ambientColor = 0x303040;
		whiteLight.shadowMapper = new NearDirectionalShadowMapper(.2);
		scene.addChild(whiteLight);

		lightPicker = new StaticLightPicker([redLight, blueLight, whiteLight]);


		//create a global shadow method
		shadowMapMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(whiteLight));
		shadowMapMethod.epsilon = .1;

		//create a global fog method
		fogMethod = new FogMethod(0, camera.lens.far*0.5, 0x000000);
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//red light material
		redLightMaterial = new TextureMaterial(Cast.bitmapTexture("assets/redlight.png"));
		redLightMaterial.alphaBlending = true;
		redLightMaterial.addMethod(fogMethod);

		//blue light material
		blueLightMaterial = new TextureMaterial(Cast.bitmapTexture("assets/bluelight.png"));
		blueLightMaterial.alphaBlending = true;
		blueLightMaterial.addMethod(fogMethod);

		//ground material
		groundMaterial = new TextureMaterial(Cast.bitmapTexture("assets/rockbase_diffuse.jpg"));
		groundMaterial.smooth = true;
		groundMaterial.repeat = true;
		groundMaterial.mipmap = true;
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.normalMap = Cast.bitmapTexture("assets/rockbase_normals.png");
		groundMaterial.specularMap = Cast.bitmapTexture("assets/rockbase_specular.png");
		groundMaterial.shadowMethod = shadowMapMethod;
		groundMaterial.addMethod(fogMethod);

		//body material
		bodyMaterial = new TextureMaterial(Cast.bitmapTexture("assets/hellknight/hellknight_diffuse.jpg"));
		bodyMaterial.gloss = 20;
		bodyMaterial.specular = 1.5;
		bodyMaterial.specularMap = Cast.bitmapTexture("assets/hellknight/hellknight_specular.png");
		bodyMaterial.normalMap = Cast.bitmapTexture("assets/hellknight/hellknight_normals.png");
		bodyMaterial.addMethod(fogMethod);
		bodyMaterial.lightPicker = lightPicker;
		bodyMaterial.shadowMethod = shadowMapMethod;
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create light billboards
		redLight.addChild(new Sprite3D(redLightMaterial, 200, 200));
		blueLight.addChild(new Sprite3D(blueLightMaterial, 200, 200));

		//AssetLibrary.enableParser(MD5MeshParser);
		//AssetLibrary.enableParser(MD5AnimParser);

		initMesh();

		//create a snowy ground plane
		ground = new Mesh(new PlaneGeometry(50000, 50000, 1, 1), groundMaterial);
		ground.geometry.scaleUV(200, 200);
		ground.castsShadows = false;
		scene.addChild(ground);

		//create a skybox
		cubeTexture = new BitmapCubeTexture(
				Cast.bitmapData("assets/skybox/grimnight_posX.png"), 
				Cast.bitmapData("assets/skybox/grimnight_negX.png"), 
				Cast.bitmapData("assets/skybox/grimnight_posY.png"), 
				Cast.bitmapData("assets/skybox/grimnight_negY.png"), 
				Cast.bitmapData("assets/skybox/grimnight_posZ.png"), 
				Cast.bitmapData("assets/skybox/grimnight_negZ.png"));
		skyBox = new SkyBox(cubeTexture);
		scene.addChild(skyBox);
	}

	/**
	 * Initialise the hellknight mesh
	 */
	private function initMesh():Void
	{
		//parse hellknight mesh
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.loadData(HellKnight_Mesh, null, null, new MD5MeshParser());
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
		cameraController.update();

		//update character animation
		if (mesh != null)
			mesh.rotationY += currentRotationInc;

		count += 0.01;

		redLight.x = Math.sin(count)*1500;
		redLight.y = 250 + Math.sin(count*0.54)*200;
		redLight.z = Math.cos(count*0.7)*1500;
		blueLight.x = -Math.sin(count*0.8)*1500;
		blueLight.y = 250 - Math.sin(count*.65)*200;
		blueLight.z = -Math.cos(count*0.9)*1500;

		view.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.ANIMATION_NODE) {

			var node:SkeletonClipNode = cast(event.asset, SkeletonClipNode);
			var name:String = event.asset.assetNamespace;
			node.name = name;
			animationSet.addAnimation(node);

			if (name == IDLE_NAME || name == WALK_NAME) {
				node.looping = true;
			} else {
				node.looping = false;
				node.addEventListener(AnimationStateEvent.PLAYBACK_COMPLETE, onPlaybackComplete);
			}

			if (name == IDLE_NAME)
				stop();
		} else if (event.asset.assetType == Asset3DType.ANIMATION_SET) {
			animationSet = cast(event.asset, SkeletonAnimationSet);
			animator = new SkeletonAnimator(animationSet, skeleton);
			for (i in 0...ANIM_NAMES.length)
				Asset3DLibrary.loadData(ANIM_CLASSES[i], null, ANIM_NAMES[i], new MD5AnimParser());

			mesh.animator = animator;
		} else if (event.asset.assetType == Asset3DType.SKELETON) {
			skeleton = cast(event.asset, Skeleton);
		} else if (event.asset.assetType == Asset3DType.MESH) {
			//grab mesh object and assign our material object
			mesh = cast(event.asset, Mesh);
			mesh.material = bodyMaterial;
			mesh.castsShadows = true;
			scene.addChild(mesh);

			//add our lookat object to the mesh
			mesh.addChild(placeHolder);

			//add key listeners
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
	}

	private function onPlaybackComplete(event:AnimationStateEvent):Void
	{
		if (animator.activeState != event.animationState)
			return;

		onceAnim = null;

		animator.play(currentAnim, stateTransition);
		animator.playbackSpeed = isMoving? movementDirection*(isRunning? RUN_SPEED : WALK_SPEED) : IDLE_SPEED;
	}

	private function playAction(val:UInt):Void
	{
		onceAnim = ANIM_NAMES[val + 2];
		animator.playbackSpeed = ACTION_SPEED;
		animator.play(onceAnim, stateTransition, 0);
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
			case Keyboard.NUMBER_1:
				playAction(1);
			case Keyboard.NUMBER_2:
				playAction(2);
			case Keyboard.NUMBER_3:
				playAction(3);
			case Keyboard.NUMBER_4:
				playAction(4);
			case Keyboard.NUMBER_5:
				playAction(5);
			case Keyboard.NUMBER_6:
				playAction(6);
			case Keyboard.NUMBER_7:
				playAction(7);
			case Keyboard.NUMBER_8:
				playAction(8);
			case Keyboard.NUMBER_9:
				playAction(9);
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
		animator.playbackSpeed = dir*(isRunning? RUN_SPEED : WALK_SPEED);

		if (currentAnim == WALK_NAME)
			return;

		currentAnim = WALK_NAME;

		if (onceAnim != null)
			return;

		//update animator
		animator.play(currentAnim, stateTransition);
	}

	private function stop():Void
	{
		isMoving = false;

		if (currentAnim == IDLE_NAME)
			return;

		currentAnim = IDLE_NAME;

		if (onceAnim != null)
			return;

		//update animator
		animator.playbackSpeed = IDLE_SPEED;
		animator.play(currentAnim, stateTransition);
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