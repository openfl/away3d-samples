package away3d.primitives;

import away3d.core.base.*;
import away3d.tools.utils.*;
import away3d.utils.*;

import openfl.geom.*;
import openfl.Vector;

class Foliage extends PrimitiveBase
{
    private var _rawVertices:Vector<Float>;
    private var _rawNormals:Vector<Float>;
    private var _rawIndices:Vector<UInt>;
    private var _rawUvs:Vector<Float>;
    private var _rawTangents:Vector<Float>;
	private var _bufferData:Vector<Float>;

    private var _off:Int;
    private var _leafSize:Float;
    private var _radius:Float;
    private var _leafCount:UInt;
    private var _positions:Vector<Float>;

    private var _pi:Float = Math.PI;

    public function new(positions:Vector<Float>, leafCount:Int, leafSize:Float, radius:Float)
    {
        super();
        _leafCount = leafCount;
        _leafSize = leafSize;
        _radius = radius;
        _positions = positions;
    }

    override private function buildGeometry( target:CompactSubGeometry ):Void
    {
        // Init raw buffers.
        _rawVertices = new Vector<Float>();
        _rawNormals = new Vector<Float>();
        _rawIndices = new Vector<UInt>();
        _rawUvs = new Vector<Float>();
        _rawTangents = new Vector<Float>();
		_bufferData = new Vector<Float>();

        // Create clusters.
        var index:Int = 0;
        var loop:Int = Std.int(_positions.length/3);
        var subloop:Int = _leafCount;
        var posx:Float, posy:Float, posz:Float;
        for(i in 0...loop)
        {
            index = 3*i;
            posx = _positions[index];
            posy = _positions[index + 1];
            posz = _positions[index + 2];
            for(j in 0...subloop)
            {
                var leafPoint:Vector3D = sphericalToCartesian(new Vector3D(_pi*Math.random(), _pi*Math.random(), _radius));
                leafPoint.x += posx;
                leafPoint.y += posy;
                leafPoint.z += posz;
                createRandomDoubleSidedTriangleAt(leafPoint, _leafSize);
            }
        }

        // Report geom data.
        target.updateIndexData(_rawIndices);
    }

    private function createRandomDoubleSidedTriangleAt(p0:Vector3D, radius:Float):Void
    {
        // Calculate vertices.
//        var p1:Vector3D = sphericalToCartesian(new Vector3D(2*_pi*Math.random(), 2*_pi*Math.random(), radius));
//        var p2:Vector3D = sphericalToCartesian(new Vector3D(2*_pi*Math.random(), 2*_pi*Math.random(), radius));
        var p1:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
        var p2:Vector3D = new Vector3D(rand(-radius, radius), rand(-radius, radius), rand(-radius, radius));
        var norm:Vector3D = p1.crossProduct(p2);
        norm.normalize();

        // Set vertices.
        p1 = p0.add(p1);
        p2 = p0.add(p2);
        _rawVertices.push(p0.x);
		_rawVertices.push(p0.y);
		_rawVertices.push(p0.z);
        _rawVertices.push(p1.x);
		_rawVertices.push(p1.y);
		_rawVertices.push(p1.z);
        _rawVertices.push(p2.x);
		_rawVertices.push(p2.y);
		_rawVertices.push(p2.z);
        _rawVertices.push(p0.x);
		_rawVertices.push(p0.y);
		_rawVertices.push(p0.z);
        _rawVertices.push(p1.x);
		_rawVertices.push(p1.y);
		_rawVertices.push(p1.z);
        _rawVertices.push(p2.x);
		_rawVertices.push(p2.y);
		_rawVertices.push(p2.z);

        // Set indices.
        _rawIndices.push(_off);
		_rawIndices.push(_off + 1);
		_rawIndices.push(_off + 2);
        _rawIndices.push(_off + 5);
		_rawIndices.push(_off + 4);
		_rawIndices.push(_off + 3);
        _off += 6;

        // Set normals.
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);
        norm.negate();
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);
        _rawNormals.push(norm.x);
		_rawNormals.push(norm.y);
		_rawNormals.push(norm.z);

        // Set Tangents.
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);
        _rawTangents.push(0);
		_rawTangents.push(0);
		_rawTangents.push(0);

        // Set UVs.
        _rawUvs.push(0);
		_rawUvs.push(0);
		_rawUvs.push(1);
		_rawUvs.push(0);
		_rawUvs.push(1);
		_rawUvs.push(1);
        _rawUvs.push(0);
		_rawUvs.push(0);
		_rawUvs.push(1);
		_rawUvs.push(0);
		_rawUvs.push(1);
		_rawUvs.push(1);
    }

    private function sphericalToCartesian(sphericalCoords:Vector3D):Vector3D
    {
        var cartesianCoords:Vector3D = new Vector3D();
        cartesianCoords.x = sphericalCoords.z*Math.sin(sphericalCoords.x)*Math.sin(sphericalCoords.y);
        cartesianCoords.y = sphericalCoords.z*Math.cos(sphericalCoords.y);
        cartesianCoords.z = sphericalCoords.z*Math.cos(sphericalCoords.x)*Math.sin(sphericalCoords.y);
        return cartesianCoords;
    }

    override private function buildUVs( target:CompactSubGeometry ):Void
    {
		target.updateData( GeomUtil.interleaveBuffers( Std.int(_rawVertices.length / 3), _rawVertices, _rawNormals, _rawTangents, _rawUvs ) );
    }

    private function rand(min:Float, max:Float):Float
    {
        return (max - min)*Math.random() + min;
    }
}