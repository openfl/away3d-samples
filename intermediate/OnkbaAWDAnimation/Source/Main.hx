/*

AWD file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal awd model.
How to create character interaction
How to set custom material on a model.

Code by Rob Bateman and LoTh
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

Model and Map by LoTH
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

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.animators.transitions.*;
import away3d.cameras.lenses.*;
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
import openfl.geom.*;
import openfl.net.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.Vector;

import utils.*;


class Main extends Sprite
{
	private var assetsRoot:String = "assets/onkba/";
	private var textureStrings:Vector<String> = Vector.ofArray(["floor_diffuse.jpg", "floor_normals.jpg", "floor_specular.jpg", "onkba_diffuse.png", "onkba_normals.jpg", "onkba_lightmap.jpg", "gun_diffuse.jpg", "gun_normals.jpg", "gun_lightmap.jpg"]);
	private var textureMaterials:Vector<BitmapTexture> = new Vector<BitmapTexture>();
	private var n:Int = 0;
	
    private var sunColor:Int = 0xAAAAA9;
	private var sunAmbient:Float = 0.4;
	private var sunDiffuse:Float = 1;
	private var sunSpecular:Float = 1;
	private var skyColor:Int = 0x333338;
	private var skyAmbient:Float = 0.2;
	private var skyDiffuse:Float = 0.5;
	private var skySpecular:Float = 0.5;
	private var fogColor:Int = 0x333338;
	private var zenithColor:Int = 0x445465;
	private var fogNear:Float = 1000;
	private var fogFar:Float = 10000;
	
    //engine variables
    private var _view:View3D;
	private var _signature:Sprite;
    private var _stats:AwayStats;
    private var _lightPicker:StaticLightPicker;
    private var _cameraController:HoverController;
	
	//light variables
	private var _sunLight:DirectionalLight;
	private var _skyLight:PointLight;
    
    //materials
    private var _skyMap:BitmapCubeTexture;
    private var _groundMaterial:TextureMaterial;
    private var _heroMaterial:TextureMaterial;
	private var _gunMaterial:TextureMaterial;
	
    //animation variables
    private var transition:CrossfadeTransition = new CrossfadeTransition(0.5);
    private var animator:SkeletonAnimator;
    private var animationSet:SkeletonAnimationSet;
    private var currentRotationInc:Float = 0;
    private var movementDirection:Float;
    private var isRunning:Bool;
    private var isMoving:Bool;
    private var currentAnim:String;
    
    //animation constants
    private static inline var ANIM_BREATHE:String = "Breathe";
    private static inline var ANIM_WALK:String = "Walk";
    private static inline var ANIM_RUN:String = "Run";
    private static inline var ANIM_DODGE:String = "Fight";
    private static inline var ANIM_PUNCH:String = "Boxe";
    private static inline var ROTATION_SPEED:Float = 3;
    private static inline var RUN_SPEED:Float = 2;
    private static inline var WALK_SPEED:Float = 1;
    private static inline var BREATHE_SPEED:Float = 1;
    private static inline var PUNCH_SPEED:Float = 1.6;
    private static inline var DODGE_SPEED:Float = 1.5;
    
    //scene objects
    private var _hero:Mesh;
	private var _heroPieces:ObjectContainer3D;
    private var _gun:Mesh;
    private var _ground:Mesh;
    
    //advanced eye 
    private var _eyes:ObjectContainer3D;
    private var _eyeL:Mesh;
    private var _eyeR:Mesh;
    private var _eyeCount:Int = 0;
    private var _eyesClosedMaterial:ColorMaterial;
    private var _eyesOpenMaterial:TextureMaterial;
    private var _eyeLook:Mesh;
    
    //navigation
    private var _prevMouseX:Float;
    private var _prevMouseY:Float;
    private var _mouseMove:Bool;
    private var _cameraHeight:Float = 0;
    
    private var _eyePosition:Vector3D;
    private var cloneActif:Bool = false;
    private var _text:TextField;
	
    private var _specularMethod:FresnelSpecularMethod;
    private var _shadowMethod:NearShadowMapMethod;
    
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
		initListeners();
		
		//kickoff asset loading
		load(textureStrings[n]);
    }
    
    /**
     * Initialise the engine
     */
    private function initEngine():Void
	{
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        
		//create the view
        _view = new View3D();
		_view.forceMouseMove = true;
        _view.backgroundColor = skyColor;
        addChild(_view);
        
		//create custom lens
        _view.camera.lens = new PerspectiveLens(70);
        _view.camera.lens.far = 30000;
        _view.camera.lens.near = 1;
        
		//setup controller to be used on the camera
        _cameraController = new HoverController(_view.camera, null, 180, 0, 1000, 10, 90);
        _cameraController.tiltAngle = 0;
        _cameraController.panAngle = 180;
        _cameraController.minTiltAngle = -60;
        _cameraController.maxTiltAngle = 60;
        _cameraController.autoUpdate = false;
        
        
        //add stats
        addChild(_stats = new AwayStats(_view, true, true));
    }
	
	/**
     * Create an instructions overlay
     */
    private function initText():Void
	{
        _text = new TextField();
        _text.defaultTextFormat = new TextFormat("_sans", 11, 0xFFFFFF);
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
        //create a light for shadows that mimics the sun's position in the skybox
        _sunLight = new DirectionalLight(-0.5, -1, 0.3);
        _sunLight.color = sunColor;
        _sunLight.ambientColor = sunColor;
        _sunLight.ambient = sunAmbient;
        _sunLight.diffuse = sunDiffuse;
        _sunLight.specular = sunSpecular;
        
        _sunLight.castsShadows = true;
        _sunLight.shadowMapper = new NearDirectionalShadowMapper(.1);
        _view.scene.addChild(_sunLight);
		
        //create a light for ambient effect that mimics the sky
        _skyLight = new PointLight();
        _skyLight.color = skyColor;
        _skyLight.ambientColor = skyColor;
        _skyLight.ambient = skyAmbient;
        _skyLight.diffuse = skyDiffuse;
        _skyLight.specular = skySpecular;
        _skyLight.y = 500;
        _skyLight.radius = 1000;
        _skyLight.fallOff = 2500;
        _view.scene.addChild(_skyLight);
		
		//create light picker for materials
        _lightPicker = new StaticLightPicker([_sunLight, _skyLight]);
		
		//generate cube texture for sky
        _skyMap = BitmapFilterEffects.vectorSky(zenithColor, fogColor, fogColor, 8);
    }
    
    /**
     * Initialise the scene materials
     */
    private function initMaterials():Void
	{
		//create gobal specular method
		_specularMethod = new FresnelSpecularMethod();
        _specularMethod.normalReflectance = 1.5;
        
		//crete global shadow method
        _shadowMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(_sunLight));
        _shadowMethod.epsilon = .1;
		
        //create the ground material
        _groundMaterial = new TextureMaterial(textureMaterials[0]);
		_groundMaterial.normalMap = textureMaterials[1];
		_groundMaterial.specularMap = textureMaterials[2];
		_groundMaterial.lightPicker = _lightPicker;
        _groundMaterial.ambient = 1;
        _groundMaterial.gloss = 30;
        _groundMaterial.specular = 1;
        _groundMaterial.repeat = true;
		_groundMaterial.specularMethod = _specularMethod;
		_groundMaterial.shadowMethod = _shadowMethod;
        _groundMaterial.addMethod(new FogMethod(fogNear, fogFar, fogColor));
		
		//create the hero material
        _heroMaterial = new TextureMaterial(textureMaterials[3]);
		_heroMaterial.normalMap = textureMaterials[4];
		_heroMaterial.lightPicker = _lightPicker;
        _heroMaterial.gloss = 16;
        _heroMaterial.specular = 0.6;
        _heroMaterial.ambient = 1;
        _heroMaterial.alphaPremultiplied = true;
        _heroMaterial.alphaThreshold = 0.9;
		_heroMaterial.specularMethod = _specularMethod;
		_heroMaterial.shadowMethod = _shadowMethod;
		_heroMaterial.addMethod(new LightMapMethod(Cast.bitmapTexture(textureMaterials[5])));
		
		//create the gun material
        _gunMaterial = new TextureMaterial(textureMaterials[6]);
		_gunMaterial.normalMap = textureMaterials[7];
		_gunMaterial.lightPicker = _lightPicker;
		_gunMaterial.gloss = 16;
        _gunMaterial.specular = 0.6;
        _gunMaterial.ambient = 1;
		_gunMaterial.specularMethod = _specularMethod;
		_gunMaterial.shadowMethod = _shadowMethod;
		_gunMaterial.addMethod(new LightMapMethod(Cast.bitmapTexture(textureMaterials[8])));
	}
    
    /**
     * Initialise the scene objects
     */
    private function initObjects():Void
	{
		//create skybox
        _view.scene.addChild(new SkyBox(_skyMap));
		
		//create ground
		_ground = new Mesh(new PlaneGeometry(100000, 100000), _groundMaterial);
        _ground.geometry.scaleUV(160, 160);
        _ground.y = -480;
        _ground.castsShadows = false;
        _view.scene.addChild(_ground);
	}

    
    /**
     * Initialise the listeners
     */
    private function initListeners():Void
	{
        //add render loop
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
        //add key listeners
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
        //navigation
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseLeave);
        stage.addEventListener(MouseEvent.MOUSE_WHEEL, onStageMouseWheel);
        stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		
        //add resize event
        stage.addEventListener(Event.RESIZE, onResize);
        onResize();
    }
	        
    /**
     * Render loop
     */
    private function onEnterFrame(event:Event):Void
	{
        //update character animation
        if (_hero != null) {
            _hero.rotationY += currentRotationInc;
			_heroPieces.transform = _hero.transform;
			
            //get the head bone
            if (animator != null && animator.globalPose.numJointPoses >= 40) {
                _eyes.transform = animator.globalPose.jointPoses[39].toMatrix3D();
                _eyes.position.add(new Vector3D(-10.22, 0, 0));
			}
			
            // look 
            _eyeR.lookAt(_eyeLook.position.add(new Vector3D(0, 1.4, 0)), new Vector3D(0, 1, 1));
            _eyeL.lookAt(_eyeLook.position.add(new Vector3D(0, -1.4, 0)), new Vector3D(0, 1, 1));
			
            // open close eye	
            _eyeCount++;
            if (_eyeCount > 300) {
	            _eyeR.material = _eyesClosedMaterial;
	            _eyeL.material = _eyesClosedMaterial;
			}
            if (_eyeCount > 309) {
	            _eyeR.material = _eyesOpenMaterial;
	            _eyeL.material = _eyesOpenMaterial;
	            _eyeCount = 0;
			}

            _cameraController.lookAtPosition = new Vector3D(_hero.x, _cameraHeight, _hero.z);
        }
		
        //update camera controler
        _cameraController.update();
		
        //update light
        _skyLight.position = _view.camera.position;
		
        //update view
        _view.render();
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
                loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
            case "png", "jpg": 
                loader.addEventListener(Event.COMPLETE, parseBitmap);
        }
		
        loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
        loader.load(new URLRequest(assetsRoot + url));
    }
    
    /**
     * Display current load
     */
    private function loadProgress(e:ProgressEvent):Void
	{
        var P:Int = Std.int(e.bytesLoaded / e.bytesTotal * 100);
        if (P != 100)
            log('Load : ' + P + ' % | ' + (Std.int(e.bytesLoaded / 1024) << 0) + ' ko\n');
        else {
            _text.text = "Cursor keys / WSAD / ZSQD - move\n";
            _text.appendText("SHIFT - hold down to run\n");
            _text.appendText("E - punch\n");
            _text.appendText("SPACE / R - guard\n");
            _text.appendText("N - random sky\n");
            _text.appendText("B - clone !\n");
		}
    }
    
    //--------------------------------------------------------------------- BITMAP DISPLAY
    
    private function parseBitmap(e:Event):Void 
	{
        log("out");
        var urlLoader:URLLoader = cast e.target;
        var loader:Loader = new Loader();
        loader.loadBytes(urlLoader.data);
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
        urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
        urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
        loader = null;
    }
    
    private function onBitmapComplete(e:Event):Void
	{
		var loaderInfo:LoaderInfo = cast e.target;
        var loader:Loader = loaderInfo.loader;
        loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBitmapComplete);
        textureMaterials.push(Cast.bitmapTexture(loaderInfo.content));
        loader.unload();
        loader = null;
        n++;
        if (n < textureStrings.length)
            load(textureStrings[n]);
        else {
            initMaterials();
			initObjects();			
        	load("onkba.awd");
        }
    }
	
    /**
     * Load AWD
     */
    private function parseAWD(e:Event):Void
	{
        var loader:URLLoader = cast e.target;
        var loader3d:Loader3D = new Loader3D(false);
        loader3d.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
        loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete, false, 0, true);
        loader3d.loadData(loader.data, null, null, new AWD2Parser());
        loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
        loader.removeEventListener(Event.COMPLETE, parseAWD);
        loader = null;
    }
    
    /**
     * Listener function for asset complete event on loader
     */
    private function onAssetComplete(event:Asset3DEvent):Void
	{
        if (event.asset.assetType == Asset3DType.SKELETON) {
            //create a new skeleton animation set
            animationSet = new SkeletonAnimationSet(3);
            //wrap our skeleton animation set in an animator object and add our sequence objects
            animator = new SkeletonAnimator(animationSet, cast(event.asset, Skeleton), true);
            
        } else if (event.asset.assetType == Asset3DType.ANIMATION_NODE) {
            //add each animation node to the animation set
            var animationNode:SkeletonClipNode = cast event.asset;
            animationSet.addAnimation(animationNode);
			
            if (animationNode.name == ANIM_BREATHE)
				stop();
			
        } else if (event.asset.assetType == Asset3DType.MESH) {
            
            var mesh:Mesh = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(event.asset, Mesh) ? cast event.asset : null;
            
            if (mesh != null) {
                if (mesh.name == "Onkba") {
                    _hero = mesh;
                    _hero.material = _heroMaterial;
                    _hero.castsShadows = true;
                    _hero.scale(10);
                }
                if (mesh.name == "Gun") {
                    _gun = mesh;
                    _gun.material = _gunMaterial;
                    _gun.castsShadows = true;
                    _gun.scale(10);
                    _gun.z = -250;
                    _gun.y = -470;
                    _gun.rotationY = 0;
                    _gun.rotationX = 0;
                }
            }
        }
    }
    
    /**
     * Check if all resource loaded
     */
    private function onResourceComplete(e:LoaderEvent):Void
	{
        //apply our animator to our mesh
        _hero.animator = animator;
		
        //add dynamic eyes
        addHeroEye();
        
        var loader3d:Loader3D = cast e.target;
        loader3d.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
        loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
        
        _view.scene.addChild(_hero);
        _view.scene.addChild(_gun);
    }
    
    /**
     * Test some Clones
     */
    private function makeClone(n:Int=20):Void {
        if (!cloneActif) {
            cloneActif = true;
            var g:Mesh;
            var decal:Int = Std.int(-(n * 400) / 2);
			for (j in 1...n) {
				for (i in 1...n) {
                    g = cast _hero.clone();
                    g.x = decal + (400 * i);
                    g.z = (decal + (400 * j));
                    if (g.x != 0 || g.z != 0)
                        _view.scene.addChild(g);
                }
            }
        }
    }
    
    /**
     * Character breath animation
     */
    private function stop():Void
	{
        isMoving = false;
		
        //update animator animation
        if (currentAnim == ANIM_BREATHE)
            return;
		
        animator.playbackSpeed = BREATHE_SPEED;
        currentAnim = ANIM_BREATHE;
        animator.play(currentAnim, transition);
    }
    
    /**
     * Character dodge animation
     */
    private function dodge():Void
	{
        //update animator animation
        if (currentAnim == ANIM_DODGE)
            return;
		
        animator.playbackSpeed = DODGE_SPEED;
        currentAnim = ANIM_DODGE;
        animator.play(currentAnim, transition, 0);
    }
    
    /**
     * Character punch animation
     */
    private function punch1():Void
	{
        //update animator animation
        if (currentAnim == ANIM_PUNCH)
            return;
		
        animator.playbackSpeed = PUNCH_SPEED;
        currentAnim = ANIM_PUNCH;
        animator.play(currentAnim, transition, 0);
    }
    
    /**
     * Character Mouvement
     */
    private function updateMovement(dir:Float):Void
	{
        isMoving = true;
		
        //update animator sequence
        var anim:String = isRunning ? ANIM_RUN : ANIM_WALK;
		
        if (currentAnim == anim)
            return;
		
        animator.playbackSpeed = dir * (isRunning ? RUN_SPEED : WALK_SPEED);
        currentAnim = anim;
        animator.play(currentAnim, transition);
    }
    
    //--------------------------------------------------------------------- KEYBORD
    
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
            case Keyboard.UP, Keyboard.W,
				Keyboard.Z: //fr
                updateMovement(movementDirection = 1);
            case Keyboard.DOWN, Keyboard.S: 
                updateMovement(movementDirection = -1);
            case Keyboard.LEFT, Keyboard.A,
				Keyboard.Q: //fr
                currentRotationInc = -ROTATION_SPEED;
            case Keyboard.RIGHT, Keyboard.D: 
                currentRotationInc = ROTATION_SPEED;
            case Keyboard.E: 
                punch1();
            case Keyboard.SPACE, Keyboard.R: 
                dodge();
            case Keyboard.B: 
                makeClone();
        }
    }
    
    /**
     * Key up listener
     */
    private function onKeyUp(event:KeyboardEvent):Void
	{
        switch (event.keyCode) {
            case Keyboard.SHIFT: 
                isRunning = false;
                if (isMoving)
                    updateMovement(movementDirection);
            case Keyboard.UP, Keyboard.W,
				Keyboard.Z, //fr
            	Keyboard.DOWN, Keyboard.S, Keyboard.SPACE, Keyboard.E, Keyboard.R: 
                stop();
            case Keyboard.LEFT, Keyboard.A,
				Keyboard.Q, //fr
            	Keyboard.RIGHT, Keyboard.D: 
                currentRotationInc = 0;
        }
    }
	
    /**
     * stage listener and mouse control
     */
    private function onResize(event:Event=null):Void
	{
        _view.width = stage.stageWidth;
        _view.height = stage.stageHeight;
        _stats.x = stage.stageWidth - _stats.width;
    }
    
    private function onStageMouseDown(ev:MouseEvent):Void
	{
        _prevMouseX = ev.stageX;
        _prevMouseY = ev.stageY;
        _mouseMove = true;
    }
    
    private function onStageMouseLeave(event:Event):Void
	{
        _mouseMove = false;
    }
    
    private function onStageMouseMove(ev:MouseEvent):Void
	{
        if (_mouseMove) {
            _cameraController.panAngle += (ev.stageX - _prevMouseX);
            _cameraController.tiltAngle += (ev.stageY - _prevMouseY);
        }
        _prevMouseX = ev.stageX;
        _prevMouseY = ev.stageY;
    }
    
    /**
     * mouseWheel listener
     */
    private function onStageMouseWheel(ev:MouseEvent):Void
	{
        _cameraController.distance -= ev.delta * 5;
		
		_cameraHeight = (_cameraController.distance < 600)? (600 - _cameraController.distance)/2 : 0;
		
        if (_cameraController.distance < 100)
            _cameraController.distance = 100;
        else if (_cameraController.distance > 2000)
            _cameraController.distance = 2000;
    }
            
    /**
     * Dynamic eyes
     */
    public function addHeroEye():Void
	{
        // materials
        _eyesClosedMaterial = new ColorMaterial(0xA13D1E);
        _eyesClosedMaterial.lightPicker = _lightPicker;
        _eyesClosedMaterial.shadowMethod = new SoftShadowMapMethod(cast(_sunLight, DirectionalLight), 20);
        _eyesClosedMaterial.gloss = 12;
        _eyesClosedMaterial.specular = 0.6;
        _eyesClosedMaterial.ambient = 1;
        
        var b:BitmapData = new BitmapData(256, 256, false);
        b.draw(textureMaterials[3].bitmapData, new Matrix(1, 0, 0, 1, -283, -197));
		
        _eyesOpenMaterial = new TextureMaterial(Cast.bitmapTexture(b));
        _eyesOpenMaterial.lightPicker = _lightPicker;
        _eyesOpenMaterial.addMethod(new EnvMapMethod(_skyMap, 0.1));
        _eyesOpenMaterial.shadowMethod = new SoftShadowMapMethod(cast(_sunLight, DirectionalLight), 20);
        _eyesOpenMaterial.gloss = 300;
        _eyesOpenMaterial.specular = 5;
        _eyesOpenMaterial.ambient = 1;
        _eyesOpenMaterial.repeat = true;
        
		//geometry
        var eyeGeometry:Geometry = new SphereGeometry(1, 32, 24);
		eyeGeometry.scaleUV(2, 1);
		
        // objects
		_heroPieces = new ObjectContainer3D();
		_heroPieces.scale(10);
		_view.scene.addChild(_heroPieces);
		
		_eyes = new ObjectContainer3D();
		
        _eyeR = new Mesh(eyeGeometry, _eyesOpenMaterial);
        _eyeR.castsShadows = false;
        _eyes.addChild(_eyeR);
		
        _eyeL = new Mesh(eyeGeometry, _eyesOpenMaterial);
		_eyeL.castsShadows = false;
        _eyes.addChild(_eyeL);
        
        _eyeR.z = _eyeL.z = 3.68;
        _eyeR.x = _eyeL.x = 6;
        _eyeR.y = 1.90;
        _eyeL.y = -1.46;
        
        _heroPieces.addChild(_eyes);
		
        _eyeLook = new Mesh(new PlaneGeometry(0.3, 0.3, 1, 1), new ColorMaterial(0xFFFFFF, 1));
        _eyeLook.rotationX = 90;
        _eyeLook.visible = false;
		
        var h:ColorMaterial = new ColorMaterial(0xFFFFFF, 1);
		
        var zone:Mesh = new Mesh(new PlaneGeometry(12, 6, 1, 1), h);
        zone.castsShadows = false;
        zone.material.blendMode = BlendMode.MULTIPLY;
        zone.addEventListener(MouseEvent3D.MOUSE_MOVE, onMeshMouseMove);
        zone.addEventListener(MouseEvent3D.MOUSE_OVER, onMeshMouseOver);
        zone.addEventListener(MouseEvent3D.MOUSE_OUT, onMeshMouseOut);
        zone.mouseEnabled = true;
        zone.rotationX = 90;
        zone.rotationZ = 90;
        zone.z = 10;
        zone.x = 6;
        zone.y = 0.22;
        _eyeLook.z = 10.2;
        _eyeLook.x = 6;
        _eyeLook.y = 0.22;
        _eyePosition = _eyeLook.position;
        
        _eyes.addChild(zone);
        _eyes.addChild(_eyeLook);
    }
    
    /**
     * mesh listener for mouse over interaction
     */
    private function onMeshMouseOver(event:MouseEvent3D):Void
	{
        cast(event.target, Mesh).showBounds = true;
        _eyeLook.visible = true;
        onMeshMouseMove(event);
    }
    
    /**
     * mesh listener for mouse out interaction
     */
    private function onMeshMouseOut(event:MouseEvent3D):Void
	{
        cast(event.target, Mesh).showBounds = false;
        _eyeLook.visible = false;
        _eyeLook.position = _eyePosition;
    }
    
    /**
     * mesh listener for mouse move interaction
     */
    private function onMeshMouseMove(event:MouseEvent3D):Void
	{
        _eyeLook.position = new Vector3D(event.localPosition.z + 6, event.localPosition.x, event.localPosition.y + 10);
    }
	
    /**
     * log for display info
     */
    private function log(t:String):Void
	{
        _text.htmlText = t;
    }
}