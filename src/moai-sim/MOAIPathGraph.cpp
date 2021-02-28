// Copyright (c) 2010-2017 Zipline Games, Inc. All Rights Reserved.
// http://getmoai.com

#include "pch.h"
#include <moai-sim/MOAIPathGraph.h>

//================================================================//
// lua
//================================================================//

//----------------------------------------------------------------//

//================================================================//
// MOAIPathFinder
//================================================================//

//----------------------------------------------------------------//
MOAIPathGraph::MOAIPathGraph ( ZLContext& context ) :
	ZLHasContext ( context ),
	MOAILuaObject ( context ) {
	
	RTTI_BEGIN ( MOAIPathGraph )
		RTTI_EXTEND ( MOAILuaObject )
	RTTI_END
}

//----------------------------------------------------------------//
MOAIPathGraph::~MOAIPathGraph () {
}

//================================================================//
// virtual
//================================================================//

//----------------------------------------------------------------//
