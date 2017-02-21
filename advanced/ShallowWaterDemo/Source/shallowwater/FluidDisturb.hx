package shallowwater;

import openfl.display.BitmapData;
import openfl.geom.Vector3D;
import openfl.Vector;

/*
 Utility class that produces natural disturbances in a fluid simulation.
 */
class FluidDisturb
{
	private var _fluid:ShallowFluid;
	private var _memoryDisturbances:Vector<MemoryDisturbance>;

	public function new( fluid:ShallowFluid ) {
		_fluid = fluid;
		_memoryDisturbances = new Vector<MemoryDisturbance>();
	}

	/*
	 Disturbs the fluid using a bitmap image.
	 */
	public function disturbBitmapInstant( x:Float, y:Float, displacement:Float, image:BitmapData ):Void {
		var ix:Int, iy:Int;
		var gray:Int;

		// Precalculations.
		var imageGridWidth:Int = Math.floor( image.width / _fluid.gridSpacing );
		var imageGridHeight:Int = Math.floor( image.height / _fluid.gridSpacing );
		var sx:Int = Math.floor( _fluid.gridWidth * x ) - Math.floor( imageGridWidth / 2 );
		var sy:Int = Math.floor( _fluid.gridHeight * y ) - Math.floor( imageGridHeight / 2 );
		var ex:Int = sx + imageGridWidth;
		var ey:Int = sy + imageGridHeight;

		// Avoid over flows.
		if( sx < 0 || sy < 0 || ex > _fluid.gridWidth || ey > _fluid.gridHeight )
			return;

		// Loop.
		for( i in sx...ex ) {
			for( j in sy...ey ) {
				ix = Math.floor( image.width * (i - sx) / imageGridWidth );
				iy = Math.floor( image.height * (j - sy) / imageGridHeight );
				gray = image.getPixel( ix, image.height - iy ) & 0x0000FF;
				if( gray != 0 )
					_fluid.displacePoint( i, j, displacement * gray / 256 );
			}
		}
	}

	/*
	 Disturbs the fluid using a bitmap image.
	 The disturbance remains for a given time.
	 */
	public function disturbBitmapMemory( x:Float, y:Float, displacement:Float, image:BitmapData, time:Int, speed:Float ):Void {
		var disturbance:MemoryDisturbance = new MemoryDisturbance( time, speed );
		_memoryDisturbances.push( disturbance );

		var ix:Int, iy:Int;
		var gray:Int;

		// Precalculations.
		var imageGridWidth:Int = Math.floor( image.width / _fluid.gridSpacing );
		var imageGridHeight:Int = Math.floor( image.height / _fluid.gridSpacing );
		var sx:Int = Math.floor( _fluid.gridWidth * x ) - Math.floor( imageGridWidth / 2 );
		var sy:Int = Math.floor( _fluid.gridHeight * y ) - Math.floor( imageGridHeight / 2 );
		var ex:Int = sx + imageGridWidth;
		var ey:Int = sy + imageGridHeight;

		// Avoid over flows.
		if( sx < 0 || sy < 0 || ex > _fluid.gridWidth || ey > _fluid.gridHeight )
			return;

		// Loop.
		for( i in sx...ex ) {
			for( j in sy...ey ) {
				ix = Math.floor( image.width * (i - sx) / imageGridWidth );
				iy = Math.floor( image.height * (j - sy) / imageGridHeight );
				gray = image.getPixel( ix, image.height - iy ) & 0x0000FF;
				if( gray != 0 )
					disturbance.addDisturbance( i, j, displacement * gray / 256 );
			}
		}
	}

	/*
	 Disturb a point with no smoothing.
	 Fast, but unnatural.
	 */
	public function disturbPoint( n:Float, m:Float, displacement:Float ):Void {
		_fluid.displacePoint( Math.floor( n * _fluid.gridWidth ), Math.floor( m * _fluid.gridHeight ), displacement );
	}

	/*
	 Produces a circular, gaussian bell shaped disturbance in the fluid.
	 Results in natural, jaggedless, drop-like disturbances.
	 n - [0, 1] - x coordinate.
	 m - [0, 1] - y coordinate.
	 displacement - z displacement of the disturbance.
	 radius - controls the opening of the gaussian bell and the wideness of the affected sub-grid.
	 */
	public function disturbPointGaussian( n:Float, m:Float, displacement:Float, radius:Float ):Void {
		// Id target point in grid.
		var epiX:Int = Math.floor( n * _fluid.gridWidth );
		var epiY:Int = Math.floor( m * _fluid.gridHeight );

		// Find start point.
		var sX:Int = Std.int(epiX - radius / 2);
		var sY:Int = Std.int(epiY - radius / 2);

		// Loop.
		var x:Int, y:Int, d:Float, dd:Float, dx:Float, dy:Float;
		var maxDis:Float = radius / 2;
		for( i in 0...Std.int(radius) ) {
			for( j in 0...Std.int(radius) ) {
				x = sX + i;
				y = sY + j;

				if( x == epiX && y == epiY ) {
					_fluid.displacePoint( x, y, displacement );
				}
				else {
					// Eval distance to epicenter.
					dx = epiX - x;
					dy = epiY - y;
					dd = dx * dx + dy * dy;
					d = Math.sqrt( dd );

					if( d < maxDis ) {
						_fluid.displacePoint( x, y, displacement * Math.pow( 2, -dd * radius / 100 ) ); // Gaussian distribution (could have many options here).
					}
				}
			}
		}
	}

	public function releaseMemoryDisturbances():Void
	{
		var loop:Int = _memoryDisturbances.length;
		for( i in 0...loop ) {
			var memoryDisturbance:MemoryDisturbance = _memoryDisturbances[i];
			memoryDisturbance.concluded = true;
		}
	}

	public function updateMemoryDisturbances():Void {
		var i:Int = 0;
		var loop:Int = _memoryDisturbances.length;
		while (i < loop) {
			var memoryDisturbance:MemoryDisturbance = _memoryDisturbances[i];

			// Advance the memory disturbance's time.
			memoryDisturbance.update();

			// Check caducity.
			if( memoryDisturbance.concluded ) {
				memoryDisturbance = null;
				_memoryDisturbances.splice( i, 1 );
				i -= 2;
				loop--;
				continue;
			}

			// Update the memory disturbance's points on the fluid.
			var subLoop:Int = memoryDisturbance.disturbances.length;
			for( j in 0...subLoop ) {
				var disturbance:Vector3D = memoryDisturbance.disturbances[j];
				_fluid.displacePointStatic( Std.int(disturbance.x), Std.int(disturbance.y), disturbance.z * memoryDisturbance.growth );
			}
			i--;
		}
	}
}