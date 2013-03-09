package
{
	import com.adobe.utils.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	
	
	[SWF(width="680", height="680", frameRate="60", backgroundColor="#000000")]
	public class Main extends Sprite
	{
		
		private var _context3D:Context3D;
		private var _vertexbuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D; 
		private var _program:Program3D;
		private var _texture:Texture;
		
		private var _geoSphere:GeoSphere;
		
		private var _camera:Camera3D;
		
		private var _dragStartPoint:Point;
		
		private var _sphereWorldMatrix:Matrix3D = new Matrix3D();
		
		private var _moveSpeed:int = 20;
		
		private var _initComplete:Boolean = true;
		
		private var _generate:TextField = new TextField();
		
		private var _loadingText:TextField = new TextField();
		
		private var _iterationsInput:TextField = new TextField();
		
		private var _lightDir:Vector3D = new Vector3D(1, 0, 1);
			
		
		public function Main()
		{
			stage.stage3Ds[0].addEventListener( Event.CONTEXT3D_CREATE, initMolehill );
			stage.stage3Ds[0].requestContext3D();
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;			
			
			addEventListener(Event.ENTER_FRAME, onRender);
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, keyDownEventHandler );   
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			stage.addEventListener(Event.RESIZE, onResize);
		}
		
		private function onMouseWheel(e:MouseEvent):void 
		{
			if(e.delta>0)
				_camera.moveForward(_moveSpeed);
			else
				_camera.moveBackward(_moveSpeed);
		}
		
		private function onMouseDown(e:MouseEvent):void 
		{
			_dragStartPoint = new Point(stage.mouseX, stage.mouseY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStopDrag);
		}
		
		private function onStopDrag(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onStopDrag);
		}
		
		private function onDrag(e:MouseEvent):void 
		{
			var dx:Number = _dragStartPoint.x - stage.mouseX;
			var dy:Number = _dragStartPoint.y - stage.mouseY;
			
			
			_sphereWorldMatrix.appendRotation(dx, new Vector3D(0, 1, 0));
			_sphereWorldMatrix.appendRotation(dy, new Vector3D(1, 0, 0));
			
			_dragStartPoint.x = stage.mouseX;
			_dragStartPoint.y = stage.mouseY;
		}
		
		private function onResize(e:Event):void 
		{
			if (!_context3D)
				return;
				
			_context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 1, true);
			_camera.aspect = stage.stageWidth / stage.stageHeight;
		}
		
		protected function keyDownEventHandler(e:KeyboardEvent):void
		{
			
			switch (e.keyCode) 
			{ 
				case Keyboard.W:
					_camera.moveForward(_moveSpeed);
					break;
				case Keyboard.S:
					_camera.moveBackward(_moveSpeed);
					break;
				case Keyboard.A:
					_camera.moveLeft(_moveSpeed);
					break;
				case Keyboard.D:
					_camera.moveRight(_moveSpeed);
					break;
				
			}
		}
		
	
		
		protected function initMolehill(e:Event):void
		{
			_context3D = stage.stage3Ds[0].context3D;			
			
			_context3D.enableErrorChecking = true;
			
			_context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 1, true);
			
			_generate.text = "Generate Planet";
			_generate.textColor = 0xffffff;
			_generate.border = true;
			_generate.borderColor = 0xffffff;
			_generate.autoSize = TextFieldAutoSize.LEFT;
			_generate.x = 10;
			_generate.y = 10;
			_generate.selectable = false;
			addChild(_generate);
			_generate.addEventListener(MouseEvent.CLICK, onClickGenerate);
			
			_loadingText.width = 680;
			_loadingText.textColor = 0xffffff;
			_loadingText.mouseEnabled = false;
			_loadingText.x = 10;
			_loadingText.y = 30;
			addChild(_loadingText);

			
			_iterationsInput.type = TextFieldType.INPUT;
			_iterationsInput.textColor = 0xffffff;
			_iterationsInput.x = 120;
			_iterationsInput.y = 10;
			_iterationsInput.text = "200";
			_iterationsInput.border = true;
			_iterationsInput.borderColor = 0xffffff;
			_iterationsInput.height = 18;
			addChild(_iterationsInput);
			
			
			
			//var bmpData:BitmapData = new BitmapData(256, 256);
			//var bitmap:Bitmap = new Bitmap(bmpData);
			//texture = _context3D.createTexture(bitmap.bitmapData.width, bitmap.bitmapData.height, Context3DTextureFormat.BGRA, false);
			//uploadTextureWithMipMaps(texture, bitmap.bitmapData);
			
			var vertexShaderAssembler : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble( Context3DProgramType.VERTEX,
				//"m44 vt0,va0, vc1 \n"+
				"m44 op, va0, vc0\n" + // pos to clipspace
				"m44 vt, va1, vc4\n"+
				"mov v0, vt \n" +// copy normals
				"mov v1, va2" // copy color
				
			);
			
			var fragmentShaderAssembler : AGALMiniAssembler= new AGALMiniAssembler();
			fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT,
				"nrm ft0.xyz, v0 \n" +
				"mov ft0.w, fc2.w \n"+
				
				"dp3 ft1, fc2, ft0 \n"+     //dot the transformed normal with light direction
				"max ft1, ft1, fc0 \n"+     //clamp any negative values to 0
				"mul ft3, v1, ft1 \n"+     //multiply fragment color by light amount
				"mul ft4, ft3, fc3 \n"+     //multiply fragment color by light color
										 
				"add oc, ft4, fc1"         //add ambient light and output the color
			);

			
			 //Temporary register component read without being written to for source operand 2 at token 3 of fragment program.
			_program = _context3D.createProgram();
			_program.upload( vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
			

			// Setup camera
			_camera = new Camera3D(
				0.1, // near
				5000, // far
				stage.stageWidth / stage.stageHeight, // aspect ratio
				29*(Math.PI/180), // vFOV
				0, 10, 1200, // position
				0, 0, 0, // target
				0, 1, 0 // up dir
			);
			
			
			_lightDir.normalize();
			
			_sphereWorldMatrix.identity();
		}
		
		private function onClickGenerate(e:MouseEvent):void 
		{
			_loadingText.text = "Generating Planet...";
			_loadingText.visible = true;
			
			setTimeout(function():void{
				_geoSphere = new GeoSphere();
				_geoSphere.create(6,int(_iterationsInput.text));
				
				_vertexbuffer = _context3D.createVertexBuffer(_geoSphere.vertices.length/_geoSphere.vertexDataSize, _geoSphere.vertexDataSize);
				_vertexbuffer.uploadFromVector(_geoSphere.vertices, 0, _geoSphere.vertices.length / _geoSphere.vertexDataSize);
				
				_indexBuffer = _context3D.createIndexBuffer(_geoSphere.indices.length);			
				_indexBuffer.uploadFromVector (_geoSphere.indices, 0, _geoSphere.indices.length);
				_loadingText.visible = false;
			},100);
		}

		
		public function uploadTextureWithMipMaps( tex:Texture, originalImage:BitmapData ):void 
		{		
			var mipWidth:int = originalImage.width;
			var mipHeight:int = originalImage.height;
			var mipLevel:int = 0;
			var mipImage:BitmapData = new BitmapData( originalImage.width, originalImage.height );
			var scaleTransform:Matrix = new Matrix();
			
			while ( mipWidth > 0 && mipHeight > 0 )
			{
				mipImage.draw( originalImage, scaleTransform, null, null, null, true );
				tex.uploadFromBitmapData( mipImage, mipLevel );
				scaleTransform.scale( 0.5, 0.5 );
				mipLevel++;
				mipWidth >>= 1;
				mipHeight >>= 1;
			}
			mipImage.dispose();
		}			
		
		protected function onRender(e:Event):void
		{
			if ( !_context3D && !_initComplete ) 
				return;
			
			_context3D.clear ( 0, 0, 0, 1 );
			
			if (_geoSphere) 
			{
				_context3D.setVertexBufferAt (0, _vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				_context3D.setVertexBufferAt(1, _vertexbuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
				_context3D.setVertexBufferAt(2, _vertexbuffer, 6, Context3DVertexBufferFormat.FLOAT_3);

				_context3D.setProgram(_program);
				
				var mat:Matrix3D = new Matrix3D();
				mat.copyFrom(_camera.worldToClipMatrix)
				mat.append(_sphereWorldMatrix);
				
				var invTransposeWorld:Matrix3D = new Matrix3D();
				invTransposeWorld.copyFrom(_sphereWorldMatrix);
				invTransposeWorld.invert();
				invTransposeWorld.transpose();
				
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mat, false);
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, invTransposeWorld, false);
				
				
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0,0,0,0])); 
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.15,0.15,0.15,0])); 
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([_lightDir.x, _lightDir.y, _lightDir.z,1])); 
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.<Number>([1,1,1,1])); 
				
				_context3D.drawTriangles(_indexBuffer);
			}
			
			_context3D.present();
		
		}
	}
}