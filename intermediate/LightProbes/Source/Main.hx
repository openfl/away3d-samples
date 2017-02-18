/*

Light probe usage in Away3D 4.0

Demonstrates:

How to use the Loader3D object to load an embedded internal obj model.
How to use LightProbe objects in combination with StaticLightPicker to simulate indirect lighting
How to use shadow mapping with point lights

Code by David Lenaerts
www.derschmale.com

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

import away3d.cameras.Camera3D;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.controllers.LookAtController;
import away3d.debug.AwayStats;
import away3d.entities.Mesh;
import away3d.events.Asset3DEvent;
import away3d.library.Asset3DLibrary;
import away3d.library.assets.Asset3DType;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.parsers.OBJParser;
import away3d.materials.LightSources;
import away3d.materials.TextureMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.FresnelSpecularMethod;
import away3d.materials.methods.HardShadowMapMethod;
import away3d.materials.methods.LightMapMethod;
import away3d.materials.methods.RimLightMethod;
import away3d.textures.BitmapTexture;
import away3d.textures.SpecularBitmapTexture;

import cornell.CornellDiffuseEnvMapFL;
import cornell.CornellDiffuseEnvMapFR;
import cornell.CornellDiffuseEnvMapNL;
import cornell.CornellDiffuseEnvMapNR;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import openfl.ui.Keyboard;
import openfl.Assets;

class Main extends Sprite
{
	//engine variables
	private var scene : Scene3D;
	private var camera : Camera3D;
	private var view : View3D;
	private var cameraController : LookAtController;

	//light objects
	private var mainLight : PointLight;
	private var lightProbeFL : LightProbe;
	private var lightProbeFR : LightProbe;
	private var lightProbeNL : LightProbe;
	private var lightProbeNR : LightProbe;

	private var mesh : Mesh;

	// movement related
	private var xDir : Float = 0;
	private var zDir : Float = 0;
	private var speed : Float = 2;
	private var mouseDown : Bool;
	private var referenceMouseX : Float;

	private var headTexture : BitmapTexture;
	private var whiteTexture : BitmapTexture;
	private var headMaterial : TextureMaterial;

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
	private function init() : Void
	{
		initEngine();
		initLights();
		initObjects();
		initListeners();
	}

	/**
	 * Initialise the engine
	 */
	private function initEngine() : Void
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		scene = new Scene3D();

		camera = new Camera3D();
		camera.lens.far = 2000;
		camera.lens.near = 20;
		camera.lookAt(new Vector3D(0, 0, 1000));

		view = new View3D();
		view.antiAlias = 16;
		view.scene = scene;
		view.camera = camera;

		//setup controller to be used on the camera
		cameraController = new LookAtController(camera);

		addChild(view);

		addChild(new AwayStats(view));
	}

	private function initLights() : Void
	{
		mainLight = new PointLight();
		mainLight.castsShadows = true;
		// maximum, small scene
		mainLight.shadowMapper.depthMapSize = 1024;
		mainLight.y = 120;
		mainLight.color = 0xffffff;
		mainLight.diffuse = 1;
		mainLight.specular = 1;
		mainLight.radius = 400;
		mainLight.fallOff = 500;
		mainLight.ambient = 0xa0a0c0;
		mainLight.ambient = .5;
		scene.addChild(mainLight);

		// each map was taken at position +/-75, 0,  +-/75
		lightProbeFL = new LightProbe(new CornellDiffuseEnvMapFL());
		lightProbeFL.x = -75;
		lightProbeFL.z = 75;
		scene.addChild(lightProbeFL);
		lightProbeFR = new LightProbe(new CornellDiffuseEnvMapFR());
		lightProbeFR.x = 75;
		lightProbeFR.z = 75;
		scene.addChild(lightProbeFR);
		lightProbeNL = new LightProbe(new CornellDiffuseEnvMapNL());
		lightProbeNL.x = -75;
		lightProbeNL.z = -75;
		scene.addChild(lightProbeNL);
		lightProbeNR = new LightProbe(new CornellDiffuseEnvMapNR());
		lightProbeNR.x = 75;
		lightProbeNR.z = -75;
		scene.addChild(lightProbeNR);
	}

	/**
	 * Initialise the listeners
	 */
	private function initListeners() : Void
	{
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		onResize();
	}

	private function onMouseDown(event : MouseEvent) : Void
	{
		mouseDown = true;
		referenceMouseX = stage.mouseX;
	}

	private function onMouseUp(event : MouseEvent) : Void
	{
		mouseDown = false;
	}

	/**
	 * Navigation and render loop
	 */
	private function onEnterFrame(event : Event) : Void
	{
		if (!mouseDown) {
			camera.x = camera.x*.9 + (stage.stageWidth*.5 - mouseX)*.05;
			camera.y = camera.y*.9 + (stage.stageHeight*.5 - mouseY)*.05;
			camera.z = - 300;
		}

		if (mesh != null) {
			if (mouseDown) {
				mesh.rotationY += (referenceMouseX - stage.mouseX)/5;
				referenceMouseX = stage.mouseX;
			}
			mesh.x += xDir*speed;
			mesh.z += zDir*speed;
			if (mesh.x < -75) mesh.x = -75;
			else if (mesh.x > 75) mesh.x = 75;
			if (mesh.z < -75) mesh.z = -75;
			else if (mesh.z > 75) mesh.z = 75;
		}

		cameraController.update();

		view.render();
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects() : Void
	{
		Asset3DLibrary.enableParser(OBJParser);

		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onCornellComplete);
		Asset3DLibrary.loadData(Assets.getBytes("assets/cornell.obj"));
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onCornellComplete(event : Asset3DEvent) : Void
	{
		var material : TextureMaterial;
		var mesh : Mesh;

		if (event.asset.assetType == Asset3DType.MESH) {
			mesh = cast event.asset;
			//create material object and assign it to our mesh
			material = new TextureMaterial(new BitmapTexture(Assets.getBitmapData("assets/cornell_baked.jpg")));
			material.normalMap = new BitmapTexture(Assets.getBitmapData("assets/cornellWallNormals.jpg"));
			material.lightPicker = new StaticLightPicker([mainLight]);
			material.shadowMethod = new HardShadowMapMethod(mainLight);
			material.specular = .25;
			material.gloss = 20;
			mesh.material = material;
			mesh.scale(100);
			mesh.geometry.subGeometries[0].autoDeriveVertexNormals = true;

			scene.addChild(mesh);

			Asset3DLibrary.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onCornellComplete);
			Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onHeadComplete);
			Asset3DLibrary.loadData(Assets.getBytes("assets/head.obj"), new AssetLoaderContext(false));
		}
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onHeadComplete(event : Asset3DEvent) : Void
	{
		var specularMethod : FresnelSpecularMethod;

		if (event.asset.assetType == Asset3DType.MESH) {
			mesh = cast event.asset;
			//create material object and assign it to our mesh
			headTexture = new BitmapTexture(Assets.getBitmapData("assets/head_diffuse.jpg"));
			whiteTexture = new BitmapTexture(new BitmapData(512, 512, false, 0xbbbbaa));
			headMaterial = new TextureMaterial(headTexture);
			headMaterial.normalMap = new BitmapTexture(Assets.getBitmapData("assets/head_diffuse.jpg"));
			headMaterial.specularMap = new SpecularBitmapTexture(Assets.getBitmapData("assets/head_specular.jpg"));
			specularMethod = new FresnelSpecularMethod();
			specularMethod.normalReflectance = .2;
			headMaterial.specularMethod = specularMethod;
			headMaterial.gloss = 10;
			headMaterial.addMethod(new RimLightMethod(0xffffff, .4, 5, RimLightMethod.ADD));
			headMaterial.addMethod(new LightMapMethod(new BitmapTexture(Assets.getBitmapData("assets/head_AO.jpg"))));
			headMaterial.lightPicker = new StaticLightPicker([mainLight, lightProbeFL, lightProbeFR, lightProbeNL, lightProbeNR]);
			headMaterial.diffuseLightSources = LightSources.PROBES;
			headMaterial.specularLightSources = LightSources.LIGHTS;

			// turn off ambient contribution from lights, it's included in the probes' contribution
			headMaterial.ambient = 0;
			mesh.scale(20);
			mesh.material = headMaterial;
			cameraController.lookAtObject = mesh;
			scene.addChild(mesh);
		}
	}

	/**
	 * Key down listener for animation
	 */
	private function onKeyDown(event : KeyboardEvent) : Void
	{
		switch (event.keyCode) {
			case Keyboard.UP:
					zDir = 1;
			case Keyboard.DOWN:
					zDir = -1;
			case Keyboard.LEFT:
					xDir = -1;
			case Keyboard.RIGHT:
					xDir = 1;
		}
	}

	private function onKeyUp(event : KeyboardEvent) : Void
	{
		switch (event.keyCode) {
			case Keyboard.UP:
			case Keyboard.DOWN:
					zDir = 0;
			case Keyboard.LEFT:
			case Keyboard.RIGHT:
					xDir = 0;
			case Keyboard.SPACE:
					switchTextures();
		}
	}

	private function switchTextures() : Void
	{
		if (headMaterial == null) return;

		if (headMaterial.texture == whiteTexture)
			headMaterial.texture = headTexture;
		else
			headMaterial.texture = whiteTexture;
	}

	/**
	 * stage listener for resize events
	 */
	private function onResize(event : Event = null) : Void
	{
		view.width = stage.stageWidth;
		view.height = stage.stageHeight;
	}
}