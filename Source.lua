-- Services
local AssetService = game : GetService( "AssetService" );
local RunService = game : GetService( "RunService" );
local Players = game : GetService( "Players" );

-- Cache
local ContentFromObject = Content.fromObject;

local UDim2FromOffset = UDim2.fromOffset;
local UDim2FromScale = UDim2.fromScale;

local BufferWriteU8 = buffer.writeu8;
local BufferCreate = buffer.create;
local BufferFill = buffer.fill;

local Color3FromRGB = Color3.fromRGB;
local InstanceNew = Instance.new;

local TableUnpack = table.unpack;
local TableClone = table.clone;

local Vector2Zero = Vector2.zero;
local Vector2New = Vector2.new;

local MathCosine = math.cos;
local MathSine = math.sin;
local MathRad = math.rad;
local MathAbs = math.abs;

local Epsilon = .001;

-- Variables
local LocalPlayer = Players.LocalPlayer;

local Height = 64;
local Width = 64;

local SizeVector = Vector2New( Width, Height );

local EditableImage = AssetService : CreateEditableImage( { Size = SizeVector } );

local Bytes = ( Width * Height ) * 4;
local Buffer = BufferCreate( Bytes );

local Label = InstanceNew( "ImageLabel" ); do
	Label.ImageContent = Content.fromObject( EditableImage );
	Label.ResampleMode = Enum.ResamplerMode.Pixelated;

	Label.Size = UDim2FromOffset( Width, Height );

	Label.Position = UDim2FromScale( .5, .5 );
	Label.AnchorPoint = Vector2New( .5, .5 );

	Label.BackgroundTransparency = 1;
end

local NegatedHeight = ( Height - 1 );
local NegatedWidth = ( Width - 1 );

local Utilities = { }; do
	function Utilities : FillOn( Canvas, PixelX, PixelY )
		for OutlineX = -1, 1 do
			for OutlineY = -1, 1 do
				if ( not Canvas[ ( PixelY + OutlineX ) * Width + ( PixelX + OutlineY ) ] ) then
					continue;
				end

				return true;
			end
		end

		return;
	end
end

-- Main
do
	local Spring = { }; do
		Spring.Connection = nil;

		Spring.Stiffness = 150;
		Spring.Damping = 12;

		Spring.Position = 0;
		Spring.Velocity = 0;
	end
	
	local Module = { }; do
		Module.OutlineColor = Color3FromRGB( 0, 0, 0 );
		Module.Color = Color3FromRGB( 255, 255, 255 );

		Module.Position = Vector2Zero;
		Module.Thickness = 1;

		Module.Rotation = 32;
		Module.Length = 7;

		Module.Alpha = 255;
		Module.Gap = 5;

		Module.Spring = Spring;
		Module.Outline = true;
	end

	-- API
	do
		function Module : Initiate( Parent )
			Label.Parent = ( Parent or InstanceNew( "ScreenGui", LocalPlayer.PlayerGui ) );
		end

		function Module : Impulse( Value )
			Spring.Velocity += ( Value * 10 );

			if ( Spring.Connection ) then
				return;
			end

			local Connection = nil; Connection = RunService.Heartbeat : Connect( function( DeltaTime )
				local NewVelocity = Spring.Velocity + ( ( -Spring.Stiffness * Spring.Position ) + ( -Spring.Damping * Spring.Velocity ) ) * DeltaTime;
				local NewPosition = Spring.Position + ( Spring.Velocity * DeltaTime );

				local AbsoluteVelocity = MathAbs( NewVelocity );
				local AbsolutePosition = MathAbs( NewPosition );

				Spring.Velocity = NewVelocity;
				Spring.Position = NewPosition;

				if ( AbsolutePosition < Epsilon ) and ( AbsoluteVelocity < Epsilon ) then
					Spring.Connection : Disconnect( );
					Spring.Connection = nil;

					Spring.Position = 0;
					Spring.Velocity = 0;
				end
			end )

			Spring.Connection = Connection;
		end

		function Module : Stepper( )
			local Rotation = MathRad( self.Rotation );
			local Position = self.Position;

			local OutlineColor = self.OutlineColor;
			local Outline = self.Outline;

			local Gap = ( self.Gap + Spring.Position );
			local Thickness = self.Thickness;

			local Color = self.Color;

			local Length = self.Length;
			local Alpha = self.Alpha;

			local CosineRotation = MathCosine( Rotation );
			local SineRotation = MathSine( Rotation );

			local PositionY = ( Height * .5 ) + Position.Y;
			local PositionX = ( Width * .5 ) + Position.X;

			BufferFill( Buffer, 0, 0, Bytes );

			local HalfThickness = Thickness * .5;
			local GapLength = Gap + Length;

			local OutlineR = OutlineColor.R * 255;
			local OutlineG = OutlineColor.G * 255;
			local OutlineB = OutlineColor.B * 255;

			local ColorR = Color.R * 255;
			local ColorG = Color.G * 255;
			local ColorB = Color.B * 255;

			local Canvas = { };

			for PixelY = 0, NegatedHeight do
				local Offset = ( NegatedHeight - PixelY ) * Width;
				local DeltaY = ( PixelY - PositionY );

				for PixelX = 0, NegatedWidth do
					local DeltaX = ( PixelX - PositionX );

					local RotationY = ( -DeltaX * SineRotation ) + ( DeltaY * CosineRotation );
					local RotationX = ( DeltaX * CosineRotation ) + ( DeltaY * SineRotation );

					local AbsoluteRotationX = MathAbs( RotationX );
					local AbsoluteRotationY = MathAbs( RotationY );

					if ( ( ( AbsoluteRotationX > HalfThickness ) or ( AbsoluteRotationY < Gap ) or ( AbsoluteRotationY > GapLength ) ) and ( ( AbsoluteRotationY > HalfThickness ) or ( AbsoluteRotationX < Gap ) or ( AbsoluteRotationX > GapLength ) ) ) then
						continue;
					end

					local Index = ( Offset + PixelX ) * 4;

					BufferWriteU8( Buffer, Index + 1, ColorG );
					BufferWriteU8( Buffer, Index + 2, ColorB );

					BufferWriteU8( Buffer, Index + 3, Alpha );
					BufferWriteU8( Buffer, Index, ColorR );

					Canvas[ PixelY * Width + PixelX ] = true;
				end
			end

			if ( Outline ) then
				for PixelY = 0, NegatedHeight do
					local Offset = ( NegatedHeight - PixelY ) * Width;

					for PixelX = 0, NegatedWidth do
						if ( Canvas[ PixelY * Width + PixelX ] ) or ( not Utilities : FillOn( Canvas, PixelX, PixelY ) ) then
							continue;
						end

						local Index = ( Offset + PixelX ) * 4;

						BufferWriteU8( Buffer, Index + 1, OutlineG );
						BufferWriteU8( Buffer, Index + 2, OutlineB );

						BufferWriteU8( Buffer, Index + 3, Alpha );
						BufferWriteU8( Buffer, Index, OutlineR );
					end
				end
			end

			EditableImage : WritePixelsBuffer( Vector2Zero, SizeVector, Buffer );
		end
	end

	return Module;
end
