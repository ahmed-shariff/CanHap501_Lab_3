/* Definitions **********************************************************************************************************/
/* define blocks and paramters*/
float             liquidHeight                        = 4;
float             liquidDensity                       = 50;
boolean           useThreeLiuquids                    = false;
FBox              l1;
FBox              l2;
FBox              l3;

/* define start and stop button */
FCircle           c1;
FCircle           c2;

/* define game ball and paramters */
float             objectDensity                       = 200;

/* define game start */
boolean           gameStart                           = false;
boolean           gameEnd                             = false;
boolean           atCenter                            = false;
boolean           runLevel                            = false;

/* define game parameters */
int maxLevel = 3;
int currentLevel = 1;
int levelProgress = 0;
int levelBase = 0;
float levelAngle = 0;
float levelForce = 0;

/* end definitions *****************************************************************************************************/ 


/* setup section *******************************************************************************************************/
void setup(){
    /* screen size definition */
    size(1000, 700);
		PhysicsSetup();
}

void PhysicsDefinitions()
{	  
		/* Start Button */

		c2                  = new FCircle(5.0);
		c2.setPosition(worldWidth/2, worldHeight/2);
		c2.setFill(255);
		c2.setStaticBody(true);
		world.add(c2);

		
		c1                  = new FCircle(1.0);
		c1.setPosition(worldWidth/2, worldHeight/2);
		c1.setFill(0, 255, 0);
		c1.setStaticBody(true);
		world.add(c1);
}

/* end setup section ***************************************************************************************************/

/* calbacks ************************************************************************************************************/

/* end callbacks *******************************************************************************************************/


/* Keyboard inputs *****************************************************************************************************/

void keyPressed()
{
		if (key == ' ')
		{
				if (!gameStart || gameEnd)
						return;
				
				if (currentLevel < maxLevel){
						currentLevel++;
						resetLevel();
				}
				else {
						gameStart = false;
						gameEnd = true;
						currentLevel = 1;
				}

				world.remove(s.h_avatar);
				world.add(s.h_avatar);
		}
		else if(key == 'n')
		{
				gameStart = false;
				gameEnd = false;
				resetLevel();
		}
}

/* end of keyboard inputs **********************************************************************************************/

/* draw section ********************************************************************************************************/
void drawLoop(){
		if(gameStart){
				if (!runLevel)
						text("Move to the center", width/2, 60);
		}
		else {
				fill(128, 128, 128);
				textAlign(CENTER);
				if ( gameEnd ) {
						text("Thank you", width/2, 60);
				}
				else {
						text("Move to the center", width/2, 60);
				}		
		}
}
/* end draw section ****************************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/

void PhysicsSimulations()
{
		if (gameEnd)
				return;
		
		if(s.h_avatar.isTouchingBody(c1)) {
				if (!gameStart) {
						gameStart = true;
						s.h_avatar.setSensor(true);
				}
				if (!runLevel){
						atCenter = true;
						runLevel = true;
						resetLevel();
				}
		} else if (s.h_avatar.isTouchingBody(c2) && atCenter) {
				runLevel = true;
		}	else {
				runLevel = false;
				atCenter = false;
		}

		if (atCenter){
				levelAngle = 0; //random(-PI, PI);
				
				switch (currentLevel){
				case 1:// calm
						levelProgress = millis() - levelBase;
						levelForce = 1.5 + levelProgress * 0.0002;
						fEE.add(levelForce * cos(levelAngle) , levelForce * sin(levelAngle));
						s.h_avatar.setDamping(500);
						break;
				case 2:// angry
						levelProgress = millis() - levelBase;

						// delayed force push
						if (levelProgress > 2000)
						{
								levelForce = 3 + levelProgress * 0.0002;
								fEE.add(levelForce * cos(levelAngle) , levelForce * sin(levelAngle));
						}
						break;
				case 3:// agitated
						levelProgress = millis() - levelBase;
						levelForce = 1.5 + levelProgress * 0.001;
						fEE.add(levelForce * cos(levelAngle) , levelForce * sin(levelAngle));

						// adding noice
						levelAngle = random(-PI, PI);
						fEE.add(1.5 * cos(levelAngle) , 1.5 * sin(levelAngle));
						break;
				}
				fEE.limit(3.5);
		}
}

void resetLevel() {
		levelProgress = 0;
		levelBase = millis();
		s.h_avatar.setDamping(000);
}

void exit() {
		PhysicsExit();
		super.exit();
}
