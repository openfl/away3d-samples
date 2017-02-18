package cornell;

import away3d.textures.BitmapCubeTexture;

import openfl.display.BitmapData;
import openfl.Assets;

class CornellDiffuseEnvMapFL extends BitmapCubeTexture
{
	private var _posX : BitmapData;
	private var _negX : BitmapData;
	private var _posY : BitmapData;
	private var _negY : BitmapData;
	private var _posZ : BitmapData;
	private var _negZ : BitmapData;

	public function new()
	{
		super (	_posX = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/posX.jpg"), _negX = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/negX.jpg"),
				_posY = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/posY.jpg"), _negY = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/negY.jpg"),
				_posZ = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/posZ.jpg"), _negZ = Assets.getBitmapData("assets/cornellEnvMap/negXposZ/negZ.jpg")
				);
	}


	override public function dispose() : Void
	{
		super.dispose();
		_posX.dispose();
		_negX.dispose();
		_posY.dispose();
		_negY.dispose();
		_posZ.dispose();
		_negZ.dispose();
	}
}