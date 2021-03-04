/********************************************************************************
Prototype cell analysis program - tested on images of mamallian cells
detects "good" and "bad" cells (based on clumps of flourescence or lack thereof)
********************************************************************************
Created by Aidan Bell & The Shaner Lab
10/7/18
********************************************************************************
Preset I found to work best for my dataset
ga:317.6849gb:15bm:150ba:8.2903

ga is Good Area (finds particles with a minimum size of this area)
gb is Good Brightness (finds particles with this brightness or greater) 

bm is Good Min (finds bright spots with this brightness or greater) 
ba is Good Area (finds bright spots with a minimum size of this area)

*/

//Calibration 'UI'

roiManager("reset");
setBatchMode(true);
Dialog.create("Program Calibration");
Dialog.addString("Preset String:",String.paste,50);

Dialog.addCheckbox("Generate preset from user selection", false);
Dialog.setInsets(0, 0, 5)
Dialog.addMessage("Will use preset string to calibrate program if left unselected") 
Dialog.show();
preset = Dialog.getString();
dinput = Dialog.getCheckbox()
garea="";
gbrightness="";
barea="";
bmean=""; 
//if user slects input
if(dinput == true){
	  if (isOpen("Results")) { 
         selectWindow("Results"); 
         run("Close"); 
    } 
	setTool(3);
	//pick good cell
	waitForUser("Select the smallest and dimmest 'good' cell\nThen click OK");
	run("Set Measurements...", "area mean min shape redirect=None decimal=1");
	run("Measure");
	garea = getResult("Area", 0);
	gbrightness = getResult("Min",0);
	if(gbrightness<8){
		gbrightness=8;
		showMessage("You selected some background pixels. \nYou may want to reattempt without selecting any, min brightness set to 8");
	}
	//print(garea);
	  if (isOpen("Results")) { 
         selectWindow("Results"); 
         run("Close"); 
    } 
	//pick bad cell bright spot
	waitForUser("Select the smallest and dimmest bright spot of a 'bad' cell\nThen click OK");
	run("Set Measurements...", "area mean min shape redirect=None decimal=1");
	run("Measure");
	bmean = getResult("Mean",0);
	barea = getResult("Area",0);
  if (isOpen("Results")) { 
         selectWindow("Results"); 
         run("Close"); 
    } 
	    //display result
	    Dialog.create("Initial calibration complete.");
		Dialog.addString("Preset String:","ga:"+garea+"gb:"+gbrightness+"bm:"+bmean+"ba:"+barea,50);
		Dialog.addMessage("String copied to clipboard") 
		String.copy("ga:"+garea+"gb:"+gbrightness+"bm:"+bmean+"ba:"+barea);
	    Dialog.show()

}
//else use pasted string to calibrate
else{
	garea=parseFloat(substring(preset,3,indexOf(preset,"gb")));
	gbrightness=parseFloat(substring(preset,indexOf(preset,"gb:")+3,indexOf(preset,"bm")));
	bmean=parseFloat(substring(preset,indexOf(preset,"bm:")+3,indexOf(preset,"ba")));
	barea=parseFloat(substring(preset,indexOf(preset,"ba:")+3,lengthOf(preset)));
	//print(""+garea +" " + gbrightness + " " +barea + " " + bmean);
}
//end calibration

//**********************************************************************************************************************************************

//start processing

a=getTitle();
run("Select None");


run("Duplicate...", "title=find_cells");

//blur
run("Gaussian Blur...", "sigma=6");
//run("Watershed");
b=getTitle();
//duplicate blurred image
run("Duplicate...", "title=bright_spots");
c=getTitle();

//threshold for cells
selectWindow(b);
setThreshold(gbrightness, 255);
setOption("BlackBackground", false);
run("Convert to Mask");
//eliminate small particles & create gaps between loosely linked cells (kinda watershedding but not really)
run("Erode");
run("Erode");
run("Dilate");
run("Dilate");
//analyze particles to find all cells
run("Analyze Particles...", "size="+garea-(garea*0.15)+"-Infinity circularity=0.2-1.00 show=Nothing add");
mid=roiManager("count");

//threshold for bright spots
selectWindow(c);
setThreshold(bmean, 255);
setOption("BlackBackground", false);
run("Convert to Mask");
//analyze particles to find all bright spots
run("Analyze Particles...", "size="+barea-(barea*0.15)+"-Infinity circularity=0.05-1.00 show=Nothing add");
bad=0;

//change name & color of all cells that are touching any bright spot
for (i = 0; i < mid; i++) {
	roiManager("select", i);
	Roi.setStrokeColor(0,255,0)
	roiManager("rename","G"+i);
	for (j = mid; j < roiManager("count"); j++) {
		roiManager('select',newArray(i,j));
   		roiManager("AND");
   		if ((i!=j)&&(selectionType>-1)) {
  	  	 roiManager("select", i);
  	  	  Roi.setStrokeColor(255,0,0);
  	  	  roiManager("rename","B"+i);
  	  	  j=nResults;
  	  	  bad++;
   		}
	}
}
//delete bright spots from roi manager
itter = roiManager("count");
for (j = mid; j < itter; j++) {
roiManager("select", mid);
roiManager("delete");

}

//rename window to display # good & bad cells
selectWindow(a);
roiManager("show all without labels");
rename("- Good:" +roiManager("count")-bad+ " Bad:" + bad + " %good:"+(100*((roiManager("count")-bad)/roiManager("count"))));
beep()

/*while (!isKeyDown("shift")) {
    wait(10);
}

      if (isOpen("Results")) { 
         selectWindow("Results"); 
         run("Close"); 
    } 
