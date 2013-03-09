package  
{
	import flash.geom.Vector3D;
	
	
	public class GeoSphere 
	{
		public var vertices:Vector.<Number> = new Vector.<Number>;
		public var indices:Vector.<uint> = new Vector.<uint>;
		
		private var middlePointIndexCache:Object = { };
	
		private var index:int = 0;
		
		public var vertexDataSize:int = 9;
		
		private var sphereRadius:Number = 400;
		
		private var iterations:int = 250;
		
		public function GeoSphere()
		{
			
		}

		public function create(recursionLevel:uint, iterations:int):void
		{
			this.iterations = iterations;
			// create 12 vertices of a icosahedron
			var t:Number = (1.0 + Math.sqrt(5.0))/ 2.0;

			addVertex(new Vertex3(-1,  t,  0));
			addVertex(new Vertex3( 1,  t,  0));
			addVertex(new Vertex3(-1, -t,  0));
			addVertex(new Vertex3( 1, -t,  0));

			addVertex(new Vertex3( 0, -1,  t));
			addVertex(new Vertex3( 0,  1,  t));
			addVertex(new Vertex3( 0, -1, -t));
			addVertex(new Vertex3( 0,  1, -t));
							
			addVertex(new Vertex3( t,  0, -1));
			addVertex(new Vertex3( t,  0,  1));
			addVertex(new Vertex3(-t,  0, -1));
			addVertex(new Vertex3(-t,  0,  1));


			// 5 faces around point 0
			createTriangleIndices(0,11,5);
			createTriangleIndices(0,5,1);
			createTriangleIndices(0,1,7);
			createTriangleIndices(0, 7, 10);
			createTriangleIndices(0, 10, 11);

			
			createTriangleIndices(1, 5, 9);
			createTriangleIndices(5, 11, 4);
			createTriangleIndices(11, 10, 2);
			createTriangleIndices(10, 7, 6);
			createTriangleIndices(7, 1, 8);
			
			createTriangleIndices(3, 9, 4);
			createTriangleIndices(3, 4, 2);
			createTriangleIndices(3, 2, 6);
			createTriangleIndices(3, 6, 8);
			createTriangleIndices(3, 8, 9);
			
			
			createTriangleIndices(4, 9, 5);
			createTriangleIndices(2, 4, 11);
			createTriangleIndices(6, 2, 10);
			createTriangleIndices(8, 6, 7);
			createTriangleIndices(9, 8, 1);

			var newIndices:Vector.<uint> = new Vector.<uint>();
			
			// refine triangles
			for (var i:uint = 0; i < recursionLevel; ++i)
			{
				newIndices.splice(0,newIndices.length);
				
				for(var k:uint=0; k<indices.length; k+=3)
				{
					// replace triangle by 4 triangles
					var a:int = getMiddlePoint(indices[k], indices[k+1]);
					var b:int = getMiddlePoint(indices[k+1], indices[k+2]);
					var c:int = getMiddlePoint(indices[k+2], indices[k]);
					
					newIndices.push(indices[k]);
					newIndices.push(a);
					newIndices.push(c);

					newIndices.push(indices[k+1]);
					newIndices.push(b);
					newIndices.push(a);

					newIndices.push(indices[k+2]);
					newIndices.push(c);
					newIndices.push(b);

					newIndices.push(a);
					newIndices.push(b);
					newIndices.push(c);
				}
				
				indices = newIndices.slice(0);
			}
			
			
			generatePlanet();
			
			computeNormals();
			
			colorPlanet();
		}
		
		private function colorPlanet():void 
		{
			var vertexCount:int = vertices.length / vertexDataSize;
			var v:Vector3D = new Vector3D();
			var n:Vector3D = new Vector3D();
			
			var vertexIndex:int = 0;
			
			// calculate min max 
			
			var min:Number = 10000;
			var max:Number = -10000;
			var i:int = 0;
			
			for (i = 0; i < vertexCount; i++) 
			{
				vertexIndex = i * vertexDataSize;
				
				v.x = vertices[vertexIndex ];
				v.y = vertices[vertexIndex  + 1];
				v.z = vertices[vertexIndex  + 2];
				var len:Number = v.length;
				if ( len < min)
					min = v.length;
				if ( len > max)
					max = len;
			}
			
			var range:Number = max - min;
			
			for (i = 0; i < vertexCount; i++) 
			{
				vertexIndex = i * vertexDataSize;
				
				v.x = vertices[vertexIndex ];
				v.y = vertices[vertexIndex  + 1];
				v.z = vertices[vertexIndex  + 2];
			
				n.x = vertices[vertexIndex + 3];
				n.y = vertices[vertexIndex + 4];
				n.z = vertices[vertexIndex + 5];
				var height : Number = v.length;
				
				if ( height < min + (range/2))
				{
					vertices[vertexIndex + 6] = 0;
					vertices[vertexIndex + 7] = 0;
					vertices[vertexIndex + 8] = 1;
				}
				else if (height >= min+(range/2) && height < min+(range/2+range/6))
				{
					vertices[vertexIndex + 6] = 0.0;
					vertices[vertexIndex + 7] = 0.5;
					vertices[vertexIndex + 8] = 0.0;
				}
				else if (height >= min+(range/2+range/6) && height < min+(range/2+2*range/6))
				{
					vertices[vertexIndex + 6] = 0.5;
					vertices[vertexIndex + 7] = 0.5;
					vertices[vertexIndex + 8] = 0.5;
				}
				else
				{
					vertices[vertexIndex + 6] = 1;
					vertices[vertexIndex + 7] = 1;
					vertices[vertexIndex + 8] = 1;
				}
			}
		}
		
		private function random():Number
		{
			return Math.random() * 2 - 1;
		}
		
		private function generatePlanet():void 
		{
			var vertexCount:int = vertices.length / vertexDataSize;
						
			var p:Vector3D = new Vector3D();
			var v:Vector3D = new Vector3D();
			for (var i:int = 0; i < iterations; i++) 
			{
				
				var n:Vector3D;
				
				do
				{
					n = new Vector3D(random(), random(), random());
				}while (n.lengthSquared == 0);
				
				n.normalize();
				
				n.scaleBy(Math.random() * sphereRadius);
				
				var move:int = int(Math.random() * 2) / 2? -1:1;
				var moveVec:Vector3D = new Vector3D();
				
				var vertexIndex:int = 0;
				var d:Number = 0;
				for (var j:int = 0; j < vertexCount; ++j) 
				{
					vertexIndex = j * vertexDataSize;
					p.x = vertices[vertexIndex ];
					p.y = vertices[vertexIndex  + 1];
					p.z = vertices[vertexIndex  + 2];
					
					v.x = p.x - n.x;
					v.y = p.y - n.y;
					v.z = p.z - n.z;
					
					d = n.dotProduct(v);
					
					moveVec.copyFrom(p);
					moveVec.normalize();
					
						
					if (d > 0)
					{
						moveVec.scaleBy(move);
						p.incrementBy(moveVec);
					}
					else
					{
						moveVec.scaleBy(-move);
						p.incrementBy(moveVec);
					}
					
					vertices[vertexIndex ] = p.x;
					vertices[vertexIndex + 1] = p.y
					vertices[vertexIndex + 2] = p.z;
				}
			}
			
			
		}
		
		private function computeNormals():void
		{
	
			var normals:Vector.<Vector.<Vector3D>> = new Vector.<Vector.<Vector3D>>;
			

			var vertexCount:int = vertices.length / vertexDataSize;
			
			for (var j:int = 0; j < vertexCount; j++) 
			{
				normals.push(new Vector.<Vector3D>);
			}
			

			var normal:Vector3D;
			
			var i:uint = 0;
			for (i = 0; i <indices.length; i+=3) 
			{
				var i1:int = indices[i] * vertexDataSize;
				var i2:int = indices[(i+1)] * vertexDataSize;
				var i3:int = indices[(i+2)] * vertexDataSize;

				var v1:Vector3D = new Vector3D(vertices[i1], vertices[i1 + 1], vertices[i1 + 2]);
				var v2:Vector3D = new Vector3D(vertices[i2], vertices[i2 + 1], vertices[i2 + 2]);
				var v3:Vector3D = new Vector3D(vertices[i3], vertices[i3 + 1], vertices[i3 + 2]);
				
				
				var n1:Vector3D = v1.subtract(v2);
				n1.normalize();
				var n2:Vector3D = v1.subtract(v3);
				n2.normalize();
				
				normal = n1.crossProduct(n2);
				normal.normalize();
					
				normals[i1/vertexDataSize].push(normal);
				normals[i2/vertexDataSize].push(normal);
				normals[i3/vertexDataSize].push(normal);
			}

			var normalsSum:Vector3D = new Vector3D();
			
			for (i = 0; i < vertexCount; ++i)
			{
				var vertexNormals:Vector.<Vector3D> = normals[i];

				for(var k:uint=0; k<vertexNormals.length; ++k)
				{
					normalsSum = normalsSum.add(vertexNormals[k]);
				}
				
				normalsSum.normalize();
				
				vertices[i * vertexDataSize + 3] = normalsSum.x;
				vertices[i * vertexDataSize + 4] = normalsSum.y;
				vertices[i * vertexDataSize + 5] = normalsSum.z;
				
				normalsSum.x = 0;
				normalsSum.y = 0;
				normalsSum.z = 0;
				
			}
		}
		
		private function addVertex(p:Vertex3):int
		{
			var length:Number = Math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
			var v:Vertex3 = new Vertex3(p.x / length,p.y / length,p.z / length);
			v.x *= sphereRadius;
			v.y *= sphereRadius;
			v.z *= sphereRadius;
			
			vertices.push(v.x);
			vertices.push(v.y);
			vertices.push(v.z);
			
			var zero:Vertex3 = new Vertex3();
			var n:Vertex3 = Vertex3.normal(v, zero);
			
			vertices.push(n.x);
			vertices.push(n.y);
			vertices.push(n.z);
			
			vertices.push(1.0);
			vertices.push(1.0);
			vertices.push(1.0);
			
			return index++;
		}
		
		private function createTriangleIndices(v1:int, v2:int, v3:int):void
		{
			indices.push(v1);
			indices.push(v2);
			indices.push(v3);
		}
		
		private function getMiddlePoint(p1:int, p2:int):int
		{
			 // first check if we have it already
			var firstIsSmaller:Boolean = p1 < p2;
			var smallerIndex:uint = firstIsSmaller ? p1 : p2;
			var greaterIndex:uint = firstIsSmaller ? p2 : p1;
			var key:uint = (smallerIndex << 16) + greaterIndex;

			if (middlePointIndexCache[key])
			{
			   return middlePointIndexCache[key];
			}

			// not in cache, calculate it
			var point1:Vertex3 = new Vertex3(vertices[p1*vertexDataSize],vertices[p1*vertexDataSize+1],vertices[p1*vertexDataSize+2]);
			var point2:Vertex3 = new Vertex3(vertices[p2*vertexDataSize],vertices[p2*vertexDataSize+1],vertices[p2*vertexDataSize+2]);
			
			var middle:Vertex3 = new Vertex3(
				(point1.x + point2.x) / 2.0, 
				(point1.y + point2.y) / 2.0, 
				(point1.z + point2.z) / 2.0);

			// add vertex makes sure point is on unit sphere
			var i:int = addVertex(middle); 

			// store it, return index
			middlePointIndexCache[key] = i;
			
			return i;
		}
	
		
	}

}