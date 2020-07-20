// Water jet encoder v1.0

string PRIVATE_KEY = "wJu=2Ibn2Al-4hWx";

key AvId;
integer MenuChannel;

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llOwnerSay("Click to start encoding");
	}
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		MenuChannel = -10000 - (integer)llFrand(100000.0);
		llListen(MenuChannel, "", AvId, "");
		llTextBox(AvId, "Enter string to encode:", MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == MenuChannel && Id == AvId) {
			string Text64 = llStringToBase64(Text);
			string Key64 = llStringToBase64(PRIVATE_KEY);
			llOwnerSay("Encoded:\n" + llXorBase64StringsCorrect(Text64, Key64));
		}
	}
}
// Water jet encoder v1.0