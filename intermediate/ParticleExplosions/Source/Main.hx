/*

Particle explosions in Away3D using the OpenFL and Haxe logos

Demonstrates:

How to split images into particles.
How to share particle geometries and animation sets between meshes and animators.
How to manually update the playhead of a particle animator using the update() function.

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com

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
import openfl.geom.*;
import openfl.utils.*;
import openfl.Lib;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.lights.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.primitives.*;
import away3d.tools.helpers.*;
import away3d.utils.*;

import openfl.Vector;

class Main extends Sprite
{
	private static inline var PARTICLE_SIZE:Int = 3;
	private static inline var NUM_ANIMATORS:Int = 4;
	
	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var cameraController:HoverController;
	
	//light variables
	private var greenLight:PointLight;
	private var orangeLight:PointLight;
	//private var whitelight:DirectionalLight;
	//private var direction:Vector3D = new Vector3D();
	private var lightPicker:StaticLightPicker;
	
	//data variables
	private var bluePoints:Vector<Vector3D> = new Vector<Vector3D>();
	private var whitePoints:Vector<Vector3D> = new Vector<Vector3D>();
	private var blueSeparation:Int;
	private var whiteSeparation:Int;
	
	//material objects
	private var whiteMaterial:ColorMaterial;
	private var blueMaterial:ColorMaterial;
	
	//particle objects
	private var blueGeometry:ParticleGeometry;
	private var whiteGeometry:ParticleGeometry;
	private var blueAnimationSet:ParticleAnimationSet;
	private var whiteAnimationSet:ParticleAnimationSet;
	
	//scene objects
	private var blueParticleMesh:Mesh;
	private var whiteParticleMesh:Mesh;
	private var blueAnimators:Vector<ParticleAnimator>;
	private var whiteAnimators:Vector<ParticleAnimator>;
	
	//navigation variables
	private var angle:Float = 0;
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	
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
		initLights();
		initMaterials();
		initParticles();
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
		
		view = new View3D();
		view.scene = scene;
		view.camera = camera;
		
		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 225, 10, 1000);
		
		addChild(view);
		
		addChild(new AwayStats(view));
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a green point light
		greenLight = new PointLight();
		greenLight.color = 0x00FF00;
		greenLight.ambient = 1;
		greenLight.fallOff = 600;
		greenLight.radius = 100;
		greenLight.specular = 2;
		scene.addChild(greenLight);
		
		//create a blue pointlight
		orangeLight = new PointLight();
		orangeLight.color = 0xFF9900;
		orangeLight.fallOff = 600;
		orangeLight.radius = 100;
		orangeLight.specular = 2;
		scene.addChild(orangeLight);
		
		//create a lightpicker for the green and blue light
		lightPicker = new StaticLightPicker([greenLight, orangeLight]);
	}
	
	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		
		//setup the blue particle material
		blueMaterial = new ColorMaterial(0x24AFC4);
		blueMaterial.alphaPremultiplied = true;
		blueMaterial.bothSides = true;
		blueMaterial.lightPicker = lightPicker;
		
		//setup the white particle material
		whiteMaterial = new ColorMaterial(0xFFFFFF, 0.2);
		whiteMaterial.alphaPremultiplied = true;
		whiteMaterial.bothSides = true;
		whiteMaterial.lightPicker = lightPicker;
	}
	
	/**
	 * Initialise the particles
	 */
	private function initParticles():Void
	{
		var bitmapData:BitmapData;
		var point:Vector3D;
		
		//create blue and white point vectors for the OpenFL image
		bitmapData = Cast.bitmapData("assets/openfl.png");
		
		for (i in 0...bitmapData.width) {
			for (j in 0...bitmapData.height) {
				point = new Vector3D(PARTICLE_SIZE*(i - bitmapData.width / 2 - 100), PARTICLE_SIZE*( -j + bitmapData.height / 2));
				if (((bitmapData.getPixel32(i, j) >> 24) & 0xff) == 0)
					whitePoints.push(point);
				else
					bluePoints.push(point);
			}
		}
		
		//define where one logo stops and another starts
		blueSeparation = bluePoints.length;
		whiteSeparation = whitePoints.length;
		
		//create blue and white point vectors for the Haxe image
		bitmapData = Cast.bitmapData("assets/haxe.png");
		
		for (i in 0...bitmapData.width) {
			for (j in 0...bitmapData.height) {
				point = new Vector3D(PARTICLE_SIZE*(i - bitmapData.width / 2 + 100), PARTICLE_SIZE*( -j + bitmapData.height / 2));
				if (((bitmapData.getPixel32(i, j) >> 24) & 0xff) == 0)
					whitePoints.push(point);
				else
					bluePoints.push(point);
			}
		}
		
		var numBlue:Int = bluePoints.length;
		var numWhite:Int = whitePoints.length;
		
		//setup the base geometry for one particle
		var plane:PlaneGeometry = new PlaneGeometry(PARTICLE_SIZE, PARTICLE_SIZE,1,1,false);
		
		//combine them into a list
		var blueGeometrySet:Vector<Geometry> = new Vector<Geometry>();
		for (i in 0...numBlue)
			blueGeometrySet.push(plane);
		
		var whiteGeometrySet:Vector<Geometry> = new Vector<Geometry>();
		for (i in 0...numWhite)
			whiteGeometrySet.push(plane);
		
		//generate the particle geometries
		blueGeometry = ParticleGeometryHelper.generateGeometry(blueGeometrySet);
		whiteGeometry = ParticleGeometryHelper.generateGeometry(whiteGeometrySet);
		
		//define the blue particle animations and init function
		blueAnimationSet = new ParticleAnimationSet(true);
		blueAnimationSet.addAnimation(new ParticleBillboardNode());
		blueAnimationSet.addAnimation(new ParticleBezierCurveNode(ParticlePropertiesMode.LOCAL_STATIC));
		blueAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
		blueAnimationSet.initParticleFunc = initblueParticleFunc;
		
		//define the white particle animations and init function
		whiteAnimationSet = new ParticleAnimationSet();
		whiteAnimationSet.addAnimation(new ParticleBillboardNode());
		whiteAnimationSet.addAnimation(new ParticleBezierCurveNode(ParticlePropertiesMode.LOCAL_STATIC));
		whiteAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
		whiteAnimationSet.initParticleFunc = initWhiteParticleFunc;
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//initialise animators vectors
		blueAnimators = new Vector<ParticleAnimator>(NUM_ANIMATORS, true);
		whiteAnimators = new Vector<ParticleAnimator>(NUM_ANIMATORS, true);
		
		//create the blue particle mesh
		blueParticleMesh = new Mesh(blueGeometry, blueMaterial);
		
		//create the white particle mesh
		whiteParticleMesh = new Mesh(whiteGeometry, whiteMaterial);
		
		for (i in 0...NUM_ANIMATORS) {
			//clone the blue particle mesh
			blueParticleMesh = cast blueParticleMesh.clone();
			blueParticleMesh.rotationY = 45*(i-1);
			scene.addChild(blueParticleMesh);
			
			//clone the white particle mesh
			whiteParticleMesh = cast whiteParticleMesh.clone();
			whiteParticleMesh.rotationY = 45*(i-1);
			scene.addChild(whiteParticleMesh);
			
			//create and start the blue particle animator
			blueAnimators[i] = new ParticleAnimator(blueAnimationSet);
			blueParticleMesh.animator = blueAnimators[i];
			scene.addChild(blueParticleMesh);
			
			//create and start the white particle animator
			whiteAnimators[i] = new ParticleAnimator(whiteAnimationSet);
			whiteParticleMesh.animator = whiteAnimators[i];
			scene.addChild(whiteParticleMesh);
		}
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
		onResize();
	}
	
	/**
	 * Initialiser function for blue particle properties
	 */
	private function initblueParticleFunc(properties:ParticleProperties):Void
	{
		properties.startTime = 0;
		properties.duration = 1;
		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.random() * Math.PI * 2;
		var r:Float = 500;
		
		if (properties.index < blueSeparation)
			properties.nodes[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(200*PARTICLE_SIZE, 0, 0);
		else
			properties.nodes[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(-200*PARTICLE_SIZE, 0, 0);
		
		properties.nodes[ParticleBezierCurveNode.BEZIER_CONTROL_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), 2*r * Math.sin(degree2));
		properties.nodes[ParticlePositionNode.POSITION_VECTOR3D] = bluePoints[properties.index];
	}
	
	/**
	 * Initialiser function for white particle properties
	 */
	private function initWhiteParticleFunc(properties:ParticleProperties):Void
	{
		properties.startTime = 0;
		properties.duration = 1;
		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.random() * Math.PI * 2;
		var r:Float = 500;
		
		if (properties.index < whiteSeparation)
			properties.nodes[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(200*PARTICLE_SIZE, 0, 0);
		else
			properties.nodes[ParticleBezierCurveNode.BEZIER_END_VECTOR3D] = new Vector3D(-200*PARTICLE_SIZE, 0, 0);
		
		properties.nodes[ParticleBezierCurveNode.BEZIER_CONTROL_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
		properties.nodes[ParticlePositionNode.POSITION_VECTOR3D] = whitePoints[properties.index];
	}
	
	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event:Event):Void
	{
		//update the camera position
		cameraController.panAngle += 0.2;
		
		//update the particle animator playhead positions
		var time:Int;
		for (i in 0...NUM_ANIMATORS) {
			time = Std.int(1000*(Math.sin(Lib.getTimer()/5000 + Math.PI*i/4) + 1));
			blueAnimators[i].update(time);
			whiteAnimators[i].update(time);
		}
		
		if (move) {
			cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		
		//update the light positions
		angle += Math.PI / 180;
		greenLight.x = Math.sin(angle) * 600;
		greenLight.z = Math.cos(angle) * 600;
		orangeLight.x = Math.sin(angle+Math.PI) * 600;
		orangeLight.z = Math.cos(angle+Math.PI) * 600;
		
		view.render();
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
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
	}
}