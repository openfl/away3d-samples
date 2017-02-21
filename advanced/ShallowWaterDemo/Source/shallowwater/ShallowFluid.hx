package shallowwater;

import openfl.display.Shader;
import openfl.display.ShaderJob;
import openfl.utils.ByteArray;
import openfl.Vector;

/*
	 Calculates displacement, normals and tangents for a fluid grid simulation
	 using shallow water wave equations.
	 Uses pixel bender shaders via Float vectors.
	 */
class ShallowFluid
{
	private var _width:Int;
	private var _height:Int;
	private var _spacing:Float;
	private var _k1:Float;
	private var _k2:Float;
	private var _k3:Float;
	private var _points:Vector<Vector<Float>>;
	private var _renderBuffer:Int = 1;
	private var _normals:Vector<Float>;
	private var _tangents:Vector<Float>;
	private var _dt:Float;
	private var _realWaveSpeed:Float;
	private var _wantedWaveSpeed:Float;
	private var _viscosity:Float;

	public function new( n:Int, m:Int, d:Float, t:Float, c:Float, mu:Float ) {
		_width = n;
		_height = m;
		_spacing = d;
		_dt = t;
		_viscosity = mu;

		// Init buffers.
		_points = new Vector<Vector<Float>>();
		_points[0] = new Vector<Float>();
		_points[1] = new Vector<Float>();
		_normals = new Vector<Float>();
		_tangents = new Vector<Float>();

		// Fill buffers.
		var a:Int = 0;
		for( j in 0...m ) {
			var y:Float = d * j;
			for( i in 0...n ) {
				_points[0].push( d * i );
				_points[0].push( y );
				_points[0].push( 0.0 );
				_points[1].push( d * i );
				_points[1].push( y );
				_points[1].push( 0.0 );
				_normals.push( 0.0 );
				_normals.push( 0.0 );
				_normals.push( 2.0 * d );
				_tangents.push( 2.0 * d );
				_tangents.push( 0.0 );
				_tangents.push( 0.0 );
				a++;
			}
		}

		// Initialize normals shader.
		//_normalsShader = new Shader( new NormalsShaderClass() as ByteArray );
		//_normalsShader.data.dd.value = [-2.0 * d];

		// Initialize tangents shader.
		//_tangentsShader = new Shader( new TangentsShaderClass() as ByteArray );
		//_tangentsShader.data.dd.value = [-2.0 * d];

		// Initialize displacement shader.
		//_displacementShader = new Shader( new DisplacementShaderClass() as ByteArray );
		//switchBuffers();

		// Evaluate wave speed Float and init constants.
		speed = c;
	}

	/*
	 Performa a calculation cycle.
	 */
	public function evaluate():Void {
		// Evaluate displacement.
		//var displacementJob:ShaderJob = new ShaderJob( _displacementShader, _points[1 - _renderBuffer], _width, _height );
		//displacementJob.start( true );

		// Evaluate normals.
		//var normalsJob:ShaderJob = new ShaderJob( _normalsShader, _normals, _width, _height );
		//normalsJob.start( true );

		// Evaluate tangents.
		//var tangentsJob:ShaderJob = new ShaderJob( _tangentsShader, _tangents, _width, _height );
		//tangentsJob.start( true );

		switchBuffers();
	}

	/*
	 Displaces a point in the current and previous buffer to a
	 given position.
	 */
	public function displacePointStatic( n:Int, m:Int, displacement:Float ):Void {
		var index:Int = _width * m + n;
		_points[_renderBuffer][3 * index + 2] = displacement;
		_points[1 - _renderBuffer][3 * index + 2] = displacement;
	}

	/*
	 Displaces a point in the current and previous buffer by a
	 given amount.
	 */
	public function displacePoint( n:Int, m:Int, displacement:Float ):Void {
		var index:Int = _width * m + n;
		_points[_renderBuffer][3 * index + 2] += displacement;
		_points[1 - _renderBuffer][3 * index + 2] += displacement;
	}

	/*
	 WaveSpeed.
	 Changes the speed of the simulation, with other collateral effects.
	 Input between >0 and <1.
	 */
	public var speed(get, set):Float;
	private function set_speed( value:Float ):Float {
		_wantedWaveSpeed = value;
		_realWaveSpeed = value * (_spacing / (2 * _dt)) * Math.sqrt( _viscosity * _dt + 2 );
		preCalculateConstants();
		return value;
	}

	private function get_speed():Float {
		return _realWaveSpeed;
	}

	/*
	 Viscosity.
	 */
	public var viscosity(get, set):Float;
	private function get_viscosity():Float {
		return _viscosity;
	}

	private function set_viscosity( value:Float ):Float {
		_viscosity = value;
		speed = _wantedWaveSpeed;
		preCalculateConstants();
		return value;
	}

	/*
	 Get fluid normals.
	 */
	public var normals(get, never):Vector<Float>;
	private function get_normals():Vector<Float> {
		return _normals;
	}

	/*
	 Get fluid tangents.
	 */
	public var tangents(get, never):Vector<Float>;
	private function get_tangents():Vector<Float> {
		return _tangents;
	}

	/*
	 Get fluid points.
	 */
	public var points(get, never):Vector<Float>;
	private function get_points():Vector<Float> {
		return _points[_renderBuffer];
	}

	/*
	 Get fluid dimensions.
	 */
	public var gridWidth(get, never):Float;
	private function get_gridWidth():Float {
		return _width;
	}

	public var gridHeight(get, never):Float;
	private function get_gridHeight():Float {
		return _height;
	}

	public var gridSpacing(get, never):Float;
	private function get_gridSpacing():Float {
		return _spacing;
	}

	private function preCalculateConstants():Void {
		var f1:Float = _realWaveSpeed * _realWaveSpeed * _dt * _dt / (_spacing * _spacing);
		var f2:Float = 1 / (_viscosity * _dt + 2);
		_k1 = (4 - 8 * f1) * f2;
		_k2 = (_viscosity * _dt - 2) * f2;
		_k3 = 2 * f1 * f2;

		//_displacementShader.data.k1.value = [_k1];
		//_displacementShader.data.k2.value = [_k2];
		//_displacementShader.data.k3.value = [_k3];
		//_displacementShader.data.dims.value = [_width - 1, _height - 1];
	}

	private function switchBuffers():Void {
		_renderBuffer = 1 - _renderBuffer;

		//_displacementShader.data.currentBuffer.input = _points[_renderBuffer];
		//_displacementShader.data.previousBuffer.input = _points[1 - _renderBuffer];
		//_displacementShader.data.currentBuffer.width = _width;
		//_displacementShader.data.currentBuffer.height = _height;
		//_displacementShader.data.previousBuffer.width = _width;
		//_displacementShader.data.previousBuffer.height = _height;
//
		//_normalsShader.data.currentBuffer.input = _points[_renderBuffer];
		//_normalsShader.data.currentBuffer.width = _width;
		//_normalsShader.data.currentBuffer.height = _height;
//
		//_tangentsShader.data.currentBuffer.input = _points[_renderBuffer];
		//_tangentsShader.data.currentBuffer.width = _width;
		//_tangentsShader.data.currentBuffer.height = _height;
	}
}