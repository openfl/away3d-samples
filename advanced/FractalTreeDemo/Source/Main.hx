/*

Dynamic tree generation and placement in a night-time scene

Demonstrates:

How to create a height map and splat map from scratch to use for realistic terrain
How to use fratacl algorithms to create a custom tree-generating geometry primitive
How to save GPU memory by cloning complex.

Code by Rob Bateman & Alejadro Santander
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
Alejandro Santander
http://www.lidev.com.ar/

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
import away3d.entities.*;
import away3d.extrusions.*;
import away3d.lights.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.utils.*;

//import com.bit101.components.Label;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.ui.*;
import openfl.utils.*;

//import uk.co.soulwire.gui.*;


class Main extends Sprite
{
	//engine variables
	private var scene:Scene3D;
	private var camera:Camera3D;
	private var view:View3D;
	private var awayStats:AwayStats;
	private var cameraController:HoverController;
	
	//light objects
	private var moonLight:DirectionalLight;
	private var cameraLight:PointLight;
	private var skyLight:DirectionalLight;
	private var lightPicker:StaticLightPicker;
	private var fogMethod:FogMethod;
	
	//material objects
	private var heightMapData:BitmapData;
	private var blendBitmapData:BitmapData;
	private var destPoint:Point = new Point();
	private var blendTexture:BitmapTexture;
	private var terrainMethod:TerrainDiffuseMethod;
	private var terrainMaterial:TextureMaterial;
	private var trunkMaterial:TextureMaterial;
	private var leafMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;
	
	//scene objects
	private var terrain:Elevation;
	private var tree:Mesh;
	private var foliage:Mesh;
	//private var gui:SimpleGUI;
	
	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var tiltSpeed:Float = 2;
	private var panSpeed:Float = 2;
	private var distanceSpeed:Float = 1000;
	private var tiltIncrement:Float = 0;
	private var panIncrement:Float = 0;
	private var distanceIncrement:Float = 0;
	
	//gui objects
	//private var treeCountLabel:Label;
	//private var polyCountLabel:Label;
	//private var terrainPolyCountLabel:Label;
	//private var treePolyCountLabel:Label;
	
	//tree configuration variables
	private var treeLevel:Int = 10;
	private var treeCount:Int = 25;
	private var treeTimer:Timer;
	private var treeDelay:Int = 0;
	private var treeSize:Float = 1000;
	private var treeMin:Float = 0.75;
	private var treeMax:Float = 1.25;
	
	//foliage configuration variables
	private var leafSize:Float = 300;
	private var leavesPerCluster:Int = 5;
	private var leafClusterRadius:Float = 400;
	
	//terrain configuration variables
	private var terrainY:Float = -10000;
	private var terrainWidth:Float = 200000;
	private var terrainHeight:Float = 50000;
	private var terrainDepth:Float = 200000;
	
	private var currentTreeCount:Int;
	private var polyCount:Int = 0;
	private var terrainPolyCount:Int;
	private var treePolyCount:Int;
	private var clonesCreated:Bool;
	
	public var minAperture:Float = 0.4;
	public var maxAperture:Float = 0.5;
	public var minTwist:Float = 0.3;
	public var maxTwist:Float = 0.6;
	
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
		initObjects();
		initGUI();
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
		camera.lens.far = 1000000;
		
		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 0, 10, 25000, 0, 70);
		
		addChild(view);
		
		awayStats = new AwayStats(view);
		addChild(awayStats);
	}
	
	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		moonLight = new DirectionalLight();
		moonLight.position = new Vector3D(3500, 4500, 10000); // Appear to come from the moon in the sky box.
		moonLight.lookAt(new Vector3D(0, 0, 0));
		moonLight.diffuse = 0.5;
		moonLight.specular = 0.25;
		moonLight.color = 0xFFFFFF;
		scene.addChild(moonLight);
		cameraLight = new PointLight();
		cameraLight.diffuse = 0.25;
		cameraLight.specular = 0.25;
		cameraLight.color = 0xFFFFFF;
		cameraLight.radius = 1000;
		cameraLight.fallOff = 2000;
		scene.addChild(cameraLight);
		skyLight = new DirectionalLight();
		skyLight.diffuse = 0.1;
		skyLight.specular = 0.1;
		skyLight.color = 0xFFFFFF;
		scene.addChild(skyLight);
		
		lightPicker = new StaticLightPicker([moonLight, cameraLight, skyLight]);
		
		//create a global fog method
		fogMethod = new FogMethod(0, 200000, 0x000000);
	}
	
	/**
	 * Initialise the material
	 */
	private function initMaterials():Void
	{
		//create skybox texture
		cubeTexture = new BitmapCubeTexture(
			Cast.bitmapData("assets/skybox/grimnight_posX.png"), Cast.bitmapData("assets/skybox/grimnight_negX.png"),
			Cast.bitmapData("assets/skybox/grimnight_posY.png"), Cast.bitmapData("assets/skybox/grimnight_negY.png"),
			Cast.bitmapData("assets/skybox/grimnight_posZ.png"), Cast.bitmapData("assets/skybox/grimnight_negZ.png"));
		
		//create tree material
		trunkMaterial = new TextureMaterial(Cast.bitmapTexture("assets/tree/bark0.jpg"));
		trunkMaterial.normalMap = Cast.bitmapTexture("assets/tree/barkNRM.png");
		trunkMaterial.specularMap = Cast.bitmapTexture("assets/tree/barkSPEC.png");
		trunkMaterial.diffuseMethod = new BasicDiffuseMethod();
		trunkMaterial.specularMethod = new BasicSpecularMethod();
		trunkMaterial.addMethod(fogMethod);
		trunkMaterial.lightPicker = lightPicker;
		
		//create leaf material
		leafMaterial = new TextureMaterial(Cast.bitmapTexture("assets/tree/leaf4.jpg"));
		leafMaterial.addMethod(fogMethod);
		leafMaterial.lightPicker = lightPicker;
		
		//create height map
		heightMapData = new BitmapData(512, 512, false, 0x0);
		heightMapData.perlinNoise(200, 200, 4, Std.int(1000*Math.random()), false, true, 7, true);
		heightMapData.draw(createGradientSprite(512, 512, 1, 0));
		
		//create terrain diffuse method
		blendBitmapData = new BitmapData(heightMapData.width, heightMapData.height, false, 0x000000);
		blendBitmapData.threshold(heightMapData, blendBitmapData.rect, destPoint, ">", 0x444444, 0xFFFF0000, 0xFFFFFF, false);
		blendBitmapData.applyFilter(blendBitmapData, blendBitmapData.rect, destPoint, new BlurFilter(16, 16, 3));
		blendTexture = new BitmapTexture(blendBitmapData);
		terrainMethod = new TerrainDiffuseMethod([Cast.bitmapTexture("assets/terrain/rock.jpg")], blendTexture, [20, 20]);

		//create terrain material
		terrainMaterial = new TextureMaterial(Cast.bitmapTexture("assets/terrain/grass.jpg"));
		terrainMaterial.diffuseMethod = terrainMethod;
		terrainMaterial.addMethod(new FogMethod(0, 200000, 0x000000)); //TODO: global fog method affects splats when updated
		terrainMaterial.lightPicker = lightPicker;
	}
	
	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{		
		//create skybox.
		scene.addChild(new SkyBox(cubeTexture));
		
		
		
		//create terrain
		terrain = new Elevation(terrainMaterial, heightMapData, terrainWidth, terrainHeight, terrainDepth, 65, 65);
		terrain.y = terrainY;
		//terrain.smoothHeightMap();
		scene.addChild(terrain);
		
		terrainPolyCount = Std.int(terrain.geometry.subGeometries[0].vertexData.length/3);
		polyCount += terrainPolyCount;
	}
	
	/**
	 * Initialise the GUI
	 */
	private function initGUI():Void
	{
		/*gui = new SimpleGUI(this);
		
		gui.addColumn("Instructions");
		var instr:String = "Click and drag to rotate camera.\n\n";
		instr += "Arrows and WASD also rotate camera.\n\n";
		instr += "Z and X zoom camera.\n\n";
		instr += "Create a tree, then clone it to\n";
		instr += "populate the terrain with trees.\n";
		gui.addLabel(instr);
		gui.addColumn("Tree");
		gui.addSlider("minAperture", 0, 1, {label:"min aperture", tick:0.01});
		gui.addSlider("maxAperture", 0, 1, {label:"max aperture", tick:0.01});
		gui.addSlider("minTwist", 0, 1, {label:"min twist", tick:0.01});
		gui.addSlider("maxTwist", 0, 1, {label:"max twist", tick:0.01});
		gui.addButton("Generate Fractal Tree", {callback:generateTree, width:160});
		gui.addColumn("Forest");
		gui.addButton("Clone!", {callback:generateClones});
		treeCountLabel = gui.addControl(Label, {text:"trees: 0"}) as Label;
		polyCountLabel = gui.addControl(Label, {text:"polys: 0"}) as Label;
		treePolyCountLabel = gui.addControl(Label, {text:"polys/tree: 0"}) as Label;
		terrainPolyCountLabel = gui.addControl(Label, {text:"polys/terrain: 0"}) as Label;
		gui.show();*/
		
		updateLabels();
	}
	
	/**
	 * Initialise the listeners
	 */
	private function initListeners():Void
	{
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.RESIZE, onResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		onResize();
	}
	
	public function generateTree():Void
	{
		if(tree != null) {
			currentTreeCount--;
			scene.removeChild(tree);
			tree = null;
		}
		
		if(foliage != null) {
			scene.removeChild(foliage);
			foliage = null;
		}
		
		createTreeShadow(0, 0);

		// Create tree.
		var treeGeometry:FractalTreeRound = new FractalTreeRound(treeSize, 10, 3, minAperture, maxAperture, minTwist, maxTwist, treeLevel);
		tree = new Mesh(treeGeometry, trunkMaterial);
		tree.rotationY = 360*Math.random();
		tree.y = terrain != null ? terrain.y + terrain.getHeightAt(tree.x, tree.z) : 0;
		scene.addChild(tree);
		
		// Create tree leaves.
		foliage = new Mesh(new Foliage(treeGeometry.leafPositions, leavesPerCluster, leafSize, leafClusterRadius), leafMaterial);
		foliage.x = tree.x;
		foliage.y = tree.y;
		foliage.z = tree.z;
		foliage.rotationY = tree.rotationY;
		scene.addChild(foliage);
		
		// Count.
		currentTreeCount++;
		treePolyCount = Std.int(tree.geometry.subGeometries[0].vertexData.length/3) + Std.int(foliage.geometry.subGeometries[0].vertexData.length/3);
		polyCount += treePolyCount;
		updateLabels();
	}
	
	public function generateClones():Void
	{
		if(tree == null || clonesCreated)
			return;
		
		// Start tree creation.
		if(treeCount > 0) {
			treeTimer = new Timer(treeDelay, treeCount - 1);
			treeTimer.addEventListener(TimerEvent.TIMER, onTreeTimer);
			treeTimer.start();
		}
		
		clonesCreated = true;
	}
	
	private function createTreeShadow(x:Float, z:Float):Void
	{
		// Paint on the terrain's shadow blend layer
		var matrix:Matrix = new Matrix();
		var dx:Float = (x/terrainWidth + 0.5)*512 - 8;
		var dy:Float = (-z/terrainDepth + 0.5)*512 - 8;
		matrix.translate(dx, dy);
		var treeShadowBitmapData:BitmapData = new BitmapData(16, 16, false, 0x0000FF);
		treeShadowBitmapData.draw(createGradientSprite(16, 16, 0, 1), matrix);
		blendBitmapData.draw(treeShadowBitmapData, matrix, null, BlendMode.ADD);
		
		// Update the terrain.
		blendTexture.bitmapData = blendBitmapData; // TODO: invalidation routine not active for blending texture
	}
	
	private function createGradientSprite(width:Float, height:Float, alpha1:Float, alpha2:Float):Sprite
	{
		var gradSpr:Sprite = new Sprite();
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(width, height, 0, 0, 0);
		gradSpr.graphics.beginGradientFill(GradientType.RADIAL, [0xFF000000, 0xFF000000], [alpha1, alpha2], [0, 255], matrix);
		gradSpr.graphics.drawRect(0, 0, width, height);
		gradSpr.graphics.endFill();
		return gradSpr;
	}
	
	private function updateLabels():Void
	{
		//treeCountLabel.text = "trees: " + currentTreeCount;
		//polyCountLabel.text = "polys: " + polyCount;
		//treePolyCountLabel.text = "polys/tree: " + treePolyCount;
		//terrainPolyCountLabel.text = "polys/terrain: " + terrainPolyCount;
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
		
		cameraController.panAngle += panIncrement;
		cameraController.tiltAngle += tiltIncrement;
		cameraController.distance += distanceIncrement;
		
		// Update light.
		cameraLight.transform = camera.transform.clone();
		
		view.render();
	}
	
	/**
	 * Key down listener for camera control
	 */
	private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W:
				tiltIncrement = tiltSpeed;
			case Keyboard.DOWN, Keyboard.S:
				tiltIncrement = -tiltSpeed;
			case Keyboard.LEFT, Keyboard.A:
				panIncrement = panSpeed;
			case Keyboard.RIGHT, Keyboard.D:
				panIncrement = -panSpeed;
			case Keyboard.Z:
				distanceIncrement = distanceSpeed;
			case Keyboard.X:
				distanceIncrement = -distanceSpeed;
		}
	}
	
	/**
	 * Key up listener for camera control
	 */
	private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode) {
			case Keyboard.UP, Keyboard.W, Keyboard.DOWN, Keyboard.S:
				tiltIncrement = 0;
			case Keyboard.LEFT, Keyboard.A, Keyboard.RIGHT, Keyboard.D:
				panIncrement = 0;
			case Keyboard.Z, Keyboard.X:
				distanceIncrement = 0;
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
	
	/**
	 * stage listener for resize events
	 */
	private function onTreeTimer(event:TimerEvent):Void
	{
		//create tree clone.
		var treeClone:Mesh = cast tree.clone();
		treeClone.x = terrainWidth*Math.random() - terrainWidth/2;
		treeClone.z = terrainDepth*Math.random() - terrainDepth/2;
		treeClone.y = terrain != null ? terrain.y + terrain.getHeightAt(treeClone.x, treeClone.z) : 0;
		treeClone.rotationY = 360*Math.random();
		treeClone.scale((treeMax - treeMin)*Math.random() + treeMin);
		scene.addChild(treeClone);
		
		//create foliage clone.
		var foliageClone:Mesh = cast foliage.clone();
		foliageClone.x = treeClone.x;
		foliageClone.y = treeClone.y;
		foliageClone.z = treeClone.z;
		foliageClone.rotationY = treeClone.rotationY;
		foliageClone.scale(treeClone.scaleX);
		scene.addChild(foliageClone);
		
		//create tree shadow clone.
		createTreeShadow(treeClone.x, treeClone.z);
		
		//count.
		currentTreeCount++;
		polyCount += treePolyCount;
		updateLabels();
	}		
	
}
