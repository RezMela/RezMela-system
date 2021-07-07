// Texture size retainer v1.1.0

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

// Description: Maintains the size of textures when the object is resized. That is,
// 				it alters the repeats and offsets to maintain the actual size of the
//				texture itself.

// v1.1.0 - take texture data from prim, not stored data

vector Scale;
integer NumberOfSides;

SaveScale() {
	Scale = llGetScale();
}
ChangeTextures() {
	vector NewScale = llGetScale();
	float Factor = NewScale.x / Scale.x;
	list Params = [];
	integer Side;
	for (Side = 0; Side < NumberOfSides; Side++) {
		Params += [
			PRIM_TEXTURE, Side
				];
	}
	list TextureData = llGetPrimitiveParams(Params);
	Params = [];
	for (Side = 0; Side < NumberOfSides; Side++) {
		integer StrideStart = Side * 4; // PRIM_TEXTURE returns [ texture, repeats, offsets, rot ]
		string Texture = llList2String(TextureData, StrideStart);
		vector Repeat = llList2Vector(TextureData, StrideStart + 1);
		vector Offset = llList2Vector(TextureData, StrideStart + 2);
		float Rotation = llList2Float(TextureData, StrideStart + 3);
		Repeat *= Factor;
		Offset *= Factor;
		Params += [
			PRIM_TEXTURE, Side,
			Texture,
			Repeat,
			Offset,
			Rotation
				];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	SaveScale();
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		NumberOfSides = llGetNumberOfSides();
		SaveScale();
	}
	changed(integer Change) {
		if (Change & CHANGED_SCALE) {
			ChangeTextures();
		}
	}
}
// Texture size retainer v1.1.0