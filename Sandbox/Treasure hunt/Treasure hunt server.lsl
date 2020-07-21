// Treasure hunt server 1.0

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

integer GEM_HIDE = -16726170;

default
{
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == GEM_HIDE) {
			llSetLinkPrimitiveParams(Sender, [
				PRIM_POS_LOCAL, <0.0, 0.0, -0.4>,
				PRIM_SIZE, <0.01, 0.01, 0.01>
				]);		}
	}
}
// Treasure hunt server 1.0