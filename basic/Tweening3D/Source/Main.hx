/*

3D Tweening example in Away3d

Demonstrates:

How to use Tweener within a 3D coordinate system.
How to create a 3D mouse event listener on a scene object.
How to return the scene coordinates of a mouse click on the surface of a scene object.

Code by Rob Bateman
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

import away3d.containers.*;
import away3d.core.pick.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.materials.*;
import away3d.primitives.*;
import away3d.utils.*;

import motion.Actuate;
import motion.MotionPath;

import openfl.display.*;
import openfl.events.*;
import openfl.geom.Vector3D;

class Main extends Sprite
{
	//engine variables
	private var _view:View3D;
	
	//scene objects
	private var _plane:Mesh; 
	private var _cube:Mesh;
	
	/**
	 * Constructor
	 */
	public function new()
	{
		super();
		
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		//setup the view
		_view = new View3D();
		addChild(_view);
		
		//setup the camera
		_view.camera.z = -600;
		_view.camera.y = 500;
		_view.camera.lookAt(new Vector3D());
		
		//setup the scene
		_cube = new Mesh(new CubeGeometry(100, 100, 100, 1, 1, 1, false), new TextureMaterial(Cast.bitmapTexture("assets/trinket_diffuse.jpg")));
		_cube.y = 50;
		_view.scene.addChild(_cube);
		
		_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture("assets/floor_diffuse.jpg")));
		_plane.pickingCollider = PickingColliderType.HAXE_FIRST_ENCOUNTERED;
		_plane.mouseEnabled = true;
		_view.scene.addChild(_plane);
		
		//add mouse listener
		_plane.addEventListener(MouseEvent3D.MOUSE_UP, _onMouseUp);
		
		//setup the render loop
		addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
	}
	
	/**
	 * render loop
	 */
	private function _onEnterFrame(e:Event):Void
	{
		_view.render();
	}
	
	/**
	 * mesh listener for mouse up interaction
	 */
	private function _onMouseUp(ev:MouseEvent3D) : Void
	{
		var path = new MotionPath ().bezier (ev.scenePosition.x, ev.scenePosition.z, _cube.x, ev.scenePosition.z);
		Actuate.motionPath(_cube, 0.5, { x: path.x, z: path.y });
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}
}