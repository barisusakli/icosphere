package  
{
	/**
	 * ...
	 * @author 
	 */
	public class Vertex3 
	{
		public var x:Number = 0.0;
		public var y:Number = 0.0;
		public var z:Number = 0.0;
		
		public function Vertex3(x:Number=0.0, y:Number=0.0, z:Number=0.0) 
		{
			this.x = x;
			this.y = y;
			this.z = z;
		}
		
		public static function normal(v1:Vertex3, v2:Vertex3):Vertex3
		{
			var n:Vertex3 = new Vertex3();
			n.x = v1.x - v2.x;
			n.y = v1.y - v2.y;
			n.z = v1.z - v2.z;
			
			var length:Number = Math.sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
			
			n.x /= length; 
			n.y /= length;
			n.z /= length;
			
			return n;
		}
		
	}

}