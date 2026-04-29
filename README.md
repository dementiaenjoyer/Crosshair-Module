# Crosshair-Module
easy to use crosshair module made using editableimages

```lua
local RunService = game : GetService( "RunService" );
local Workspace = game : GetService( "Workspace" );

local CurrentCamera = Workspace.CurrentCamera;
local Center = CurrentCamera.ViewportSize * .5;

local Crosshair = require( script.Parent.Crosshair );
local Spring = Crosshair.Spring;

Crosshair.Thickness = 1;

Spring.Stiffness /= 2;
Spring.Damping /= 2;

Crosshair : Initiate( );

RunService.RenderStepped : Connect( function( DeltaTime )
	local NewRotation = Crosshair.Rotation + 1;
	Crosshair.Rotation = NewRotation;
	
	if ( NewRotation % 32 == 0 ) then
		Crosshair : Impulse( 16 );
	end
	
	Crosshair : Stepper( );
end )
