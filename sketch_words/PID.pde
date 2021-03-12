/**
 * Based on:
 **********************************************************************************************************************
 * @file       sketch_2_Hello_Wall.pde
 * @author     Steve Ding, Colin Gallacher, Antoine Weill--Duflos
 * @version    V1.0.0
 * @date       09-February-2021
 * @brief      PID example with random position of a target
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
*/

/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;
import java.util.*;
/* end library imports *************************************************************************************************/  


/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 

ControlP5 cp5;

Knob PKnob, IKnob, DKnob;
Slider smoothingSlider, looptimeSlider;
Textlabel forceText, infoTextLabel, infoTextX, infoTextY;
boolean EnablePath = false;

/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
boolean           exitCalled                         = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerMeter                      = 3000.0;
float             radsPerDegree                       = 0.01745;

/* pantagraph link parameters in meters */
float             l                                   = 0.07;
float             L                                   = 0.09;


/* end effector radius in meters */
float             rEE                                 = 0.006;


/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);
PVector           oldangles                           = new PVector(0, 0);
PVector           diff                                = new PVector(0, 0);


/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0);
float             posEE_YOffset                        = 0.0;
float             posEE_XOffset                        = 0.0;

/* device graphical position */
PVector           deviceOrigin                        = new PVector(0, 0);

/* World boundaries reference */
final int         worldPixelWidth                     = 1000;
final int         worldPixelHeight                    = 650;

float x_m,y_m;

// used to compute the time difference between two loops for differentiation
long oldtime = 0;
// for changing update rate
int iter = 0;

/// PID stuff

float P = 0.0;
// for I
float I = 0;
float cumerrorx = 0;
float cumerrory = 0;
// for D
float oldex = 0.0f;
float oldey = 0.0f;
float D = 0;

//for exponential filter on differentiation
float diffx = 0;
float diffy = 0;
float buffx = 0;
float buffy = 0;
float smoothing = 0.80;

float xr = 0;
float yr = 0;

// checking everything run in less than 1ms
long timetaken= 0;

// set loop time in usec (note from Antoine, 500 is about the limit of my computer max CPU usage)
int looptime = 500;


/* graphical elements */
PShape endEffector;
PFont f;
/* end elements definition *********************************************************************************************/ 

/* UI definitions ******************************************************************************************************/ 
/* end UI definitions **************************************************************************************************/ 

/* writely settings ****************************************************************************************************/
/* end writely settings ************************************************************************************************/ 


/* setup section *******************************************************************************************************/
void PIDSetup(){
		/* put setup code here, run once: */
		
		/* GUI setup */
    smooth();
		cp5 = new ControlP5(this);


		/* device setup */
  
		/**  
		 * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
		 * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
		 * to explicitly state the serial port will look like the following for different OS:
		 *
		 *      windows:      haplyBoard = new Board(this, "COM10", 0);
		 *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
		 *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
		 */ 
		haplyBoard          = new Board(this, Serial.list()[0], 0);
		widgetOne           = new Device(widgetOneID, haplyBoard);
		pantograph          = new Pantograph();
  
		widgetOne.set_mechanism(pantograph);
  
		widgetOne.add_actuator(1, CCW, 2);
		widgetOne.add_actuator(2, CW, 1);
 
		widgetOne.add_encoder(1, CCW, 241, 10752, 2);
		widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
		widgetOne.device_set_parameters();
    
  
		/* visual elements setup */
		background(0);
		deviceOrigin.add(worldPixelWidth/2, 0);
  
		/* create pantagraph graphics */
		create_pantagraph();
  
		/* setup framerate speed */
		frameRate(baseFrameRate);
    f = createFont("Arial",16,true); // STEP 2 Create Font
  
		/* setup simulation thread to run at 1kHz */ 
		thread("SimulationThread");
}

/* end setup section ***************************************************************************************************/

/* calbacks ************************************************************************************************************/

/* end callbacks *******************************************************************************************************/


/* end of keyboard inputs **********************************************************************************************/

/* draw section ********************************************************************************************************/
void PIDDraw(){
		/* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
		if(renderingForce == false){
				background(255); 
				update_animation(posEE.x + posEE_XOffset, posEE.y + posEE_YOffset);
		}
}
/* end draw section ****************************************************************************************************/

int noforce = 0;
long timetook = 0;
long looptiming = 0;
float dist_X, dist_Y;

/* simulation section for PID controlls ********************************************************************************/
public void SimulationThread(){
		while(1==1) {
				if (exitCalled)
						break;
				long starttime = System.nanoTime();
				long timesincelastloop=starttime-timetaken;
				iter+= 1;
				// we check the loop is running at the desired speed (with 10% tolerance)
				if(timesincelastloop >= looptime*1000*1.1) {
						float freq = 1.0/timesincelastloop*1000000.0;
						// println("caution, freq droped to: "+freq + " kHz");
				}
				else if(iter >= 1000) {
						float freq = 1000.0/(starttime-looptiming)*1000000.0;
						// println("loop running at "  + freq + " kHz");
						iter=0;
						looptiming=starttime;
				}
    
				timetaken=starttime;
    
				renderingForce = true;
    
				if(haplyBoard.data_available()){
						/* GET END-EFFECTOR STATE (TASK SPACE) */
						widgetOne.device_read_data();
      
						noforce = 0;
						angles.set(widgetOne.get_device_angles());
    
						posEE.set(widgetOne.get_device_position(angles.array()));

						posEE.set(device_to_graphics(posEE)); 
						x_m = xr*300; 
						y_m = yr*300+350;//mouseY;
      
						// Torques from difference in endeffector and setpoint, set gain, calculate force
						float xE = pixelsPerMeter * posEE.x + posEE_XOffset;
						float yE = pixelsPerMeter * posEE.y + posEE_YOffset; // adins some space above for the UI
						long timedif = System.nanoTime()-oldtime;

						dist_X = x_m-xE;
						cumerrorx += dist_X*timedif*0.000000001;
						dist_Y = y_m-yE;
						cumerrory += dist_Y*timedif*0.000000001;
						//println(dist_Y*k + " " +dist_Y*k);
						// println(timedif);
						if(timedif > 0) {
								buffx = (dist_X-oldex)/timedif*1000*1000;
								buffy = (dist_Y-oldey)/timedif*1000*1000;            

								diffx = smoothing*diffx + (1.0-smoothing)*buffx;
								diffy = smoothing*diffy + (1.0-smoothing)*buffy;
								oldex = dist_X;
								oldey = dist_Y;
								oldtime=System.nanoTime();
						}
    
						// Forces are constrained to avoid moving too fast
  
						fEE.x = constrain(P*dist_X,-4,4) + constrain(I*cumerrorx,-4,4) + constrain(D*diffx,-8,8);

      
						fEE.y = constrain(P*dist_Y,-4,4) + constrain(I*cumerrory,-4,4) + constrain(D*diffy,-8,8); 


						if(noforce==1)
						{
								fEE.x=0.0;
								fEE.y=0.0;
						}
						widgetOne.set_device_torques(graphics_to_device(fEE).array());
						//println(f_y);
						/* end haptic wall force calculation */
      
				}
    
    
				
				widgetOne.device_write_torques();
  
  
				renderingForce = false;
				long timetook=System.nanoTime()-timetaken;
				if(timetook >= 1000000) {
						//println("Caution, process loop took: " + timetook/1000000.0 + "ms");
				}
				else {
						while(System.nanoTime()-starttime < looptime*1000) {
								//println("Waiting");
						}
				}
    
		}
}

/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/

void PIDExit() {
		exitCalled = true;
		println("Executing exit");

		// rying to make sure that the device's torques are set to 0
		widgetOne.device_set_parameters();
		widgetOne.set_device_torques(new float[]{0, 0});
		widgetOne.device_write_torques();
}

void create_pantagraph(){
		float lAni = pixelsPerMeter * l;
		float LAni = pixelsPerMeter * L;
		float rEEAni = pixelsPerMeter * rEE;
  
		endEffector = createShape(ELLIPSE, deviceOrigin.x, deviceOrigin.y, 2*rEEAni, 2*rEEAni);
		endEffector.setStroke(color(0));
		strokeWeight(5);  
}


void update_animation(float xE, float yE){
		background(255);
		
		noFill();
		stroke(color(255, 0, 0));
		strokeWeight(1.5);
		PFont f = createFont("Arial", 16);
		textFont(f, 16);
		
		//push current transformation matrixto stack
    pushMatrix();

		// Calculating the current position of the end effector
		xE = pixelsPerMeter * xE;
		yE = pixelsPerMeter * yE;

		// Not rendering the joints of haply

		// Set transformation matrix o the location of the end effector and draw the end effector graphic
		translate(xE, yE);
		shape(endEffector);
		popMatrix(); // Reset the transformation matrix
		
		textFont(f,16);                  // STEP 3 Specify font to be used
		fill(0);                         // STEP 4 Specify font color 
		
		// When rendering the target position
		// x_m = xr*300+500; 
		// //println(x_m + " " + mouseX);")
		// y_m = yr*300+350;//mouseY;
		// pushMatrix();
		// translate(x_m, y_m);
		// shape(target);
		// popMatrix();
}


PVector device_to_graphics(PVector deviceFrame){
		return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}


PVector graphics_to_device(PVector graphicsFrame){
		return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}
