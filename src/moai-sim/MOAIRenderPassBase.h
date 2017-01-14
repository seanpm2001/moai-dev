// Copyright (c) 2010-2017 Zipline Games, Inc. All Rights Reserved.
// http://getmoai.com

#ifndef	MOAIRENDERPASSBASE_H
#define	MOAIRENDERPASSBASE_H

#include <moai-sim/MOAIDrawable.h>

class MOAIColor;
class MOAIFrameBuffer;
class MOAIPartition;

//================================================================//
// MOAIRenderPass
//================================================================//
class MOAIRenderPassBase :
	public virtual MOAILuaObject,
	public virtual MOAIDrawable {
private:

	u32				mClearFlags;
	u32				mClearColor;
	u32				mClearMode;

	MOAILuaSharedPtr < MOAIColor >			mClearColorNode;
	MOAILuaSharedPtr < MOAIFrameBuffer >	mFrameBuffer;

	//----------------------------------------------------------------//
	static int		_getClearMode			( lua_State* L );
	static int		_getFrameBuffer			( lua_State* L );
	static int		_pushRenderPass			( lua_State* L );
	static int		_setClearColor			( lua_State* L );
	static int		_setClearDepth			( lua_State* L );
	static int		_setClearMode			( lua_State* L );
	static int		_setFrameBuffer			( lua_State* L );

protected:

	//----------------------------------------------------------------//
	void			ClearSurface			();

public:

	GET_SET ( u32, ClearFlags, mClearFlags );
	GET_SET ( u32, ClearMode, mClearMode );

	enum {
		CLEAR_NEVER,
		CLEAR_ALWAYS,
		CLEAR_ON_BUFFER_FLAG,
	};

	//----------------------------------------------------------------//
	MOAIFrameBuffer*	GetFrameBuffer			();
						MOAIRenderPassBase		();
						~MOAIRenderPassBase		();
	void				RegisterLuaClass		( MOAILuaState& state );
	void				RegisterLuaFuncs		( MOAILuaState& state );
	void				SetClearColor			( MOAIColor* color );
	void				SetFrameBuffer			( MOAIFrameBuffer* frameBuffer = 0 );
};

#endif
