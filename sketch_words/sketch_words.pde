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
FCircle           g2;
FBox              g1;

/* define game start */
boolean           gameStart                           = false;
boolean           gameEnd                             = false;
boolean           atCenter                            = false;
boolean           runLevel                            = false;

/* define game parameters */
int maxLevel = 3;
int currentLevel = 1;

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

		c2                  = new FCircle(3.0);
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
				
				if (currentLevel < maxLevel)
						currentLevel++;
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
				atCenter = true;
				runLevel = true;		
		} else if (s.h_avatar.isTouchingBody(c2) && atCenter) {
				runLevel = true;
		}	else {
				runLevel = false;
				atCenter = false;
		}

		if (atCenter){
				switch (currentLevel){
				case 1:
						
						break;
				case 2:
						
						break;
				case 3:
						
						break;
				}
		}
}

void exit() {
		PhysicsExit();
		super.exit();
}
