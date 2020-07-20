string FontName = "Arial";
integer FontSize = 64;

default
{
	state_entry()
	{
		string Text = "B";	// change this to the letter you want

		string CommandList = "";
		// get the size vector
		vector Size  = osGetDrawStringSize("vector", Text, FontName, FontSize);
		CommandList = osSetFontName(CommandList, FontName);
		CommandList = osSetFontSize(CommandList, FontSize);
		// find top left point for the text to start
		// (64 because half 128, the size of the texture)
		integer X = 64 - ((integer)Size.x / 2);	
		integer Y = 64 - ((integer)Size.y / 2);
		CommandList = osMovePen(CommandList, X, Y);
		CommandList = osDrawText(CommandList, Text);
		osSetDynamicTextureData("", "vector", CommandList, "width:128,height:128", 0 );
	}
}