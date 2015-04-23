import controlP5.*;
import processing.serial.*;
import javax.swing.*;
SecondApplet sScreen;
Serial myPort;

int index = 0;
boolean serial;
int arrayLength = 100;
int arrayWidth = 8;
PFont f1, f2, f3, f4, f5, f6;

ControlP5 cp5;
ListBox l;
controlP5.Button startButton;
controlP5.Button dfrButton;
controlP5.Button lcsgButton;
controlP5.Button pbrButton;
controlP5.Button okButton;
controlP5.Textfield textField;

int tableHeight = 226;
int[] rowHeights;

int mode = 10;

String[] currentSesh = {
  "", 
  "", 
  "", 
  "", 
  "", 
  "", 
  "", 
  ""
};

float[] currentRun = new float[arrayWidth];

String[] headings = {
  "Name", 
  "Obstacle Course", 
  "Smash and Grab", 
  "Obstacle Course", 
  "Zombies", 
  "Ammo Used", 
  "Penalty Time", 
  "Total Time"
};

int[] penaltyTimes = {
  20, 30, 40, 50, 60, 70
};
//int[] penaltyTimesI = {20,30,40,50,60,70};

int columGap = 150;
int headingHeight = 96;
int currentSeshHeight = 120;

void setup() {
  size(1200, 786);

  PFrame f = new PFrame(500, 786);
  f.setTitle("Timer");
  fill(0);

  if (frame != null) {
    frame.setResizable(true);
  }

  loadFiles();

  serial = startSerial();

  //Create fonts
  f1 = createFont("Calibri", 50);
  f2 = createFont("Calibri Bold", 20);
  f3 = createFont("Calibri Bold", 17);
  f4 = createFont("Arial Unicode MS", 15);
  f6 = createFont("Arial Unicode MS", 12);

  setupCP5();

  rowHeights = new int[arrayLength];
  for (int i = 0; i < rowHeights.length; i++) {
    rowHeights[i] = tableHeight + (i * 20);
  }

  sScreen.resetTimer();
  sScreen.resetTimer1();

  mode = 10; //Resets the mode to the start as the button callback is triggered during setup of buttons
}

void draw() {
  background(0);
  frame.setTitle("Apocalypse Party 2015. FPS = " + int(frameRate));

  control();

  //Text
  fill(255);
  textFont(f1);
  textAlign(CENTER);
  text("Current Session", width/2, 50);
  text("Ranking", width/2, 180);

  alternatingBars(index, 25);

  //Text for Headings and Current Session
  fill(255);
  textFont(f2);
  textAlign(CENTER);  

  rowOfText(headings, columGap, headingHeight);
  rowOfText(currentSesh, columGap, currentSeshHeight);

  //Text for ranking table
  displayMainTable(data);
}

void displayMainTable(float[][] _data) {
  boolean sortByMax = false;
  float[][] displayData = sortResults(7, sortByMax, _data, index);
  int[][] colorTable = colorArray(displayData);
  for (int i = 0; i < index; i++) { 
    String[] displayArray = floatToStringRow(displayData[i]);
    rowOfText(displayArray, 150, rowHeights[i], colorTable[i]);
  }
}

String[] floatToStringRow(float[] _data) {
  String[] strings;
  int a = _data.length;
  strings = new String[a];
  strings[0] = names[int(_data[0])];
  for (int i = 1; i < a; i++) {
    if (_data[i] == 0) {
      strings[i] = "";
    } else {
      strings[i] = String.format("%.2f", _data[i]);
    }
  }
  return strings;
}

int red = color(255, 0, 0);
int pink = color(255, 220, 0);
int yellow = color(255, 50, 255);
int white = color(255, 255, 255);

int[][] colorArray(float[][] dat) {

  float[] maskMin = findMinMax(dat, false);
  float[] maskMax = findMinMax(dat, true);
  int[][] colourArray = new int[dat.length][dat[0].length];

  for (int i = 0; i < dat.length; i++) {
    colourArray[i][0] = white;
  }

  for (int i = 1; i < dat[0].length; i++) {
    for (int j = 0; j < dat.length; j++) {
      if (dat[j][i] == maskMax[i]) {
        colourArray[j][i] = pink;
      } else if (dat[j][i] == maskMin[i]) {
        colourArray[j][i] = yellow;
      } else {
        colourArray[j][i] = white;
      }
    }
  }
  return colourArray;
}

float[] findMinMax(float[][] dat, boolean max) {

  float[] minMax = new float[dat[0].length];
  for (int i = 0; i < dat[0].length; i++) {
    if (!max) {
      minMax[i] = 2147483647;
    }
  } 
  for (int i = 0; i < dat[0].length; i++) {
    for (int j = 0; j < dat.length; j++) {
      //        println("i="+i+"j="+j);
      if (max) {
        if (dat[j][i] > minMax[i]) {
          minMax[i] = dat[j][i];
        }
      } else if (!max) {
        if (dat[j][i] < minMax[i]) {
          minMax[i] = dat[j][i];
        }
      }
    }
  }
  return minMax;
}

float[][] sortResults(int row, boolean max, float[][] _data, int count) {

  FloatList sortList;
  sortList = new FloatList();
  float[][] sortedTable = new float[count][_data[0].length];

  for (int i = 0; i < count; i++) {
    sortList.append(_data[i][row]);
  }

  //Sort for fastest or slowest
  sortList.sortReverse();
  if (!max) {
    sortList.sort();
  }

  //Generate a list of the ranked positions
  for (int i = 0; i < count; i++) {
    for (int j = 0; j <count; j++) {
      if (_data[j][row] == sortList.get(i)) {
        sortedTable[i] = _data[j];
      }
    }
  }
  return sortedTable;
}

boolean nameSet = false, obstacleCourse;
String name;

void control() {
  switch(mode) {

  case 10:
    redON();
    if (nameSet) {
      clearCurrentArrays();
      currentSesh[0] = name;
      currentRun[0] = nameCode(name, names);
      startButton.show();
      sScreen.setTime1(10000);
      mode = 20;
    }
    break;

  case 20:
    //Wait for start button to be pressed, start() will advance to next mode
    break;

  case 30:
    redOFF();
    greenON();
    sScreen.startTimer();
    mode = 40;
    break;

  case 40:
    startButton.hide();
    lcsgButton.show();
    mode = 60;
    break;

  case 60: //First obstacle course
    if (serialData) {
      redON();
      greenOFF();
      float t = float(sScreen.getTime());
      currentRun[1] = t;
      float ft = t/1000;
      currentSesh[1] = String.format("%.2f", ft);
      resetSerialData();
      pbrButton.show();
      lcsgButton.hide();
      mode = 70;
    }
    break;

  case 70: //Smash and grab
    if (serialData) {
      float t = float(sScreen.getTime());
      currentRun[2] = t - currentRun[0];
      float ft = (t/1000) - currentRun[0]/1000;
      currentSesh[2] = String.format("%.2f", ft);
      resetSerialData();
      dfrButton.show();
      lcsgButton.show();
      pbrButton.hide();
      sScreen.setTime1(penaltyTimes[penaltyVal]*100);
      sScreen.startTimer1();
      sScreen.timerSwap();
      sScreen.showTimer1();
      mode = 80;
    }
    break;

  case 80:
    if (serialData) {
      if (lcsg) {
        obstacleCourse = true;
        resetSerialData();
        lcsgButton.hide();
        mode = 90;
      } else if (dfr) { //If zombie run this should trigger, only dfr should be hit, with out lcsg.
        float t = float(sScreen.getTime());
        currentRun[4] = t - currentRun[2] - currentRun[1];
        float ft = (t/1000) - currentRun[2]/1000 - currentRun[1]/1000;
        currentSesh[4] = String.format("%.2f", ft);
        resetSerialData();
        hideAllButtons();
        mode = 100;
      }
    }
    break;

  case 90: //If obstacle course run this should trigger.
    if (serialData) {
      float t = float(sScreen.getTime());
      currentRun[3] = t - currentRun[1] - currentRun[2];
      float ft =(t/1000) - currentRun[1]/1000 - currentRun[2]/1000;
      currentSesh[3] = String.format("%.2f", ft);
      resetSerialData();
      hideAllButtons();
      mode = 100;
    }
    break;

  case 100:
    sScreen.stopTimer();
    sScreen.stopTimer1();
    float t = float(sScreen.getTime());
    currentRun[6] = t;
    t /= 1000;
    currentSesh[6] = String.format("%.2f", t);
    mode = 105;
    nameSet = false;
    break;

  case 105:
    if (obstacleCourse) {
      mode = 108;
    } else {
      textField.show();
      mode = 107;
    }
    break;

  case 107:
    //Ok button or data entry will move to next case.
    break;

  case 108:
    textField.hide();
    okButton.hide();
    for (int i = 0; i < currentRun.length; i++) {
      data[index][i] = currentRun[i];
    }
    //    data[index] = currentRun;
    index++;
    //    writeTextFile();//////////////////////////////////////Commented Out for testing////////////////////
    mode = 110;
    break;

  case 110:
    //Wait for name to be set
    if (nameSet) {
      mode = 10;
      sScreen.resetTimer();
      sScreen.resetTimer1();
    }
    break;
  }
}

void ammo(String theText) {
  if (validateText(theText)) {
    currentRun[5] = int(theText);
    currentSesh[5] = theText;
    mode = 108;
  }
}

void OK(int theValue) {
  String theText = textField.getText();
  if (validateText(theText)) {
    currentRun[5] = int(theText);
    currentSesh[5] = theText;
    mode = 108;
  }
}

boolean validateText(String text) {
  boolean isNull = text.equals("") ? true : false;
  int n = int(text);
  if (!isNull && n > 0) {
    return true;
  } else {
    return false;
  }
}

void Start(int theValue) {
  mode += 10;
}

void LCSG(int theValue) {
  lcsg = true;
  serialData = true;
}

void DFR(int theValue) {
  dfr = true;
  serialData = true;
}

void PBR(int theValue) {
  pbr = true;
  serialData = true;
  penaltyVal = 4;
}

void hideAllButtons() {
  lcsgButton.hide();
  pbrButton.hide();
  dfrButton.hide();
  startButton.hide();
  okButton.hide();
}

int nameCode(String _name, String[] _names) {
  int c = 99;
  for (int i = 0; i < _names.length; i++) {
    if (_name.equals(_names[i])) {
      c = i;
    }
  }
  return c;
}

void clearCurrentArrays() {
  for (int i = 0; i < 7; i++) {
    currentSesh[i] = "";
    currentRun[i] = 0;
  }
}

String blockedSensors;
boolean lcsg, dfr, pbr, yesReceived, noReceived, serialData, greenON, redON;
int penaltyVal;

void serialEvent (Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  print(inString);
  if (inString != null) {
    blockedSensors = "";

    String match[] = match(inString, "lcsg");
    if (match != null) {
      lcsg = true;
      serialData = true;
    }

    match = match(inString, "dfr");
    if (match != null) {
      dfr = true;
      serialData = true;
    }

    match = match(inString, "pbr");
    if (match != null) {
      pbr = true;
      serialData = true;
      penaltyVal = pbInt(inString);
    }

    inString = trim(inString);
    String match2[] = match(inString, "yes.");
    if (match2 != null) {
      yesReceived = true;
    } 
    match2 = match(inString, "no.");
    if (match2 != null) {
      noReceived = true;
      blockedSensors = inString;
    }
  }
}

int pbInt(String string) {
  String numbers = string.substring(3);
  int val = int(numbers);
  return val;
}

void greenON() {
  if (!greenON) {
    if (serial) {
      myPort.write("greenON.");
      myPort.clear();
    }
    greenON = true;
    serialData = false;
  }
}

void greenOFF() {
  if (greenON) {
    if (serial) {
      myPort.write("greenOFF.");
      myPort.clear();
    }
    //    println("Green OFF");
    greenON = false;
    serialData = false;
  }
}

void redON() {
  if (!redON) {
    if (serial) {
      myPort.write("redON.");
      myPort.clear();
    }
    //    println("Red ON");
    redON = true;
    serialData = false;
  }
}

void redOFF() {
  if (redON) {
    if (serial) {
      myPort.write("redOFF.");
      myPort.clear();
    }
    //    println("Red OFF");
    redON = false;
    serialData = false;
  }
}

void resetSerialData() {
  serialData = false;
  lcsg = false;
  dfr = false;
  pbr = false;
}

void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup() && theEvent.name().equals("myList")) {
    int selection = (int)theEvent.group().value();
    updateName(selection);
  }
}

void updateName(int selection) {
  if (mode == 110 || mode == 10) {
    l.captionLabel().set(names[selection]);
    data[index][0] = selection;
    name = names[int(data[index][0])];
    currentSesh[0] = names[int(data[index][0])];
    nameSet = true;
  }
}

void rowOfText(String[] text, int colSpacing, int hheight) {

  float numOfCols = text.length;
  int ceil = ceil(numOfCols / 2);
  int evenOffset = 0;

  if (numOfCols % 2 < 1) {
    evenOffset = colSpacing /2;
  }

  for (int i = 0; i < numOfCols; i++) {
    text(text[i], width/2 + (colSpacing * (i - numOfCols + ceil) + evenOffset), hheight);
  }
}

void rowOfText(String[] ttext, int colSpacing, int hheight, color[] colors) {

  float numOfCols = ttext.length;
  int ceil = ceil(numOfCols / 2);
  int evenOffset = 0;

  if (numOfCols % 2 < 1) {
    evenOffset = colSpacing /2;
  }

  for (int i = 0; i < numOfCols; i++) {
    fill(colors[i]);
    text(ttext[i], width/2 + (colSpacing * (i - numOfCols + ceil) + evenOffset), hheight);
  }
} 

void alternatingBars(int count, int max) {

  int w = 1150;

  //Alternating Bars    
  fill(40);
  stroke(40);
  rectMode(CENTER);

  for (int i = 1; i < count + 1 && i < max; i = i + 2) {
    rect(width/2, (201 + (i * 20)), w, 19, 7);
  }

  rect(width/2, 114, w, 24, 7);
}

void setupCP5() {

  //Set up listbox
  cp5 = new ControlP5(this);
  l = cp5.addListBox("myList")
    .setPosition(6, 21)
      .setSize(120, 500)
        .setItemHeight(15)
          .setBarHeight(15)
            .setColorBackground(color(255, 255, 255))
              .setColorActive(color(50))
                .setColorForeground(color(255, 100, 100))
                  .setColorLabel(color(0))
                    .actAsPulldownMenu(true);
  ;

  l.captionLabel()
    .toUpperCase(true)
      .set("Select a Name")
        .setColor(#000000)
          .style().marginTop = 3;
  l.valueLabel().style().marginTop = 3;

  for (int i=0; i< names.length; i++) {
    ListBoxItem lbi = l.addItem(names[i], i);
    lbi.setColorBackground(#EAEAEA);
  }

  ControlFont cFont = new ControlFont(f2);

  //Set up textField
  textField = cp5.addTextfield("ammo")
    .setPosition(1000, 20)
      .setSize(60, 25)
        .setFont(cFont)
          .setFocus(true)
            .hide()
              ;

  //Set up buttons
  startButton = cp5.addButton("Start")
    .setValue(0)
      .setPosition(1100, 20)
        .setSize(60, 25)
          .setId(0)
            .activateBy(ControlP5.RELEASE)
              .hide()
                ;

  startButton.captionLabel()
    .setFont(cFont)
      .setSize(20)
        .toUpperCase(false)
          .align(ControlP5.CENTER, ControlP5.CENTER)
            ;

  okButton = cp5.addButton("OK")
    .setValue(0)
      .setPosition(1100, 20)
        .setSize(60, 25)
          .setId(0)
            .activateBy(ControlP5.RELEASE)
              .hide()
                ;

  okButton.captionLabel()
    .setFont(cFont)
      .setSize(20)
        .toUpperCase(false)
          .align(ControlP5.CENTER, ControlP5.CENTER)
            ;

  lcsgButton = cp5.addButton("LCSG")
    .setPosition(1000, 20)
      .setSize(60, 25)
        .setId(1)
          .hide()
            ;

  lcsgButton.captionLabel()
    .setFont(cFont)
      .setSize(20)
        .toUpperCase(false)
          .align(ControlP5.CENTER, ControlP5.CENTER)
            ;

  dfrButton = cp5.addButton("DFR")
    .setPosition(1100, 20)
      .setSize(60, 25)
        .setId(1)
          .hide()
            ;

  dfrButton.captionLabel()
    .setFont(cFont)
      .setSize(20)
        .toUpperCase(false)
          .align(ControlP5.CENTER, ControlP5.CENTER)
            ;

  pbrButton = cp5.addButton("PBR")
    .setPosition(900, 20)
      .setSize(60, 25)
        .setId(1)
          .hide()
            ;

  pbrButton.captionLabel()
    .setFont(cFont)
      .setSize(20)
        .toUpperCase(false)
          .align(ControlP5.CENTER, ControlP5.CENTER)
            ;
}

float[][] data = new float[arrayLength][arrayWidth];
String[] names;

void loadFiles() {

  String loadlist[] = loadStrings("list.txt");
  for (int i = 0; i < loadlist.length; i++) {
    String[] split = split(loadlist[i], ',');
    for (int j = 0; j < split.length; j++) {
      data[i][j] = float(split[j]);
    }
    index++;
  }

  // Import Names
  names = loadStrings("names.txt");
}

void writeTextFile() {

  //Create string for saving to text file
  String[] listString = new String[index];
  for (int i = 0; i < index; i++) {
    listString[i] = join(nf(int(data[i]), 0), ",");
  }

  //Save to text file
  saveStrings("list.txt", listString);
}

boolean startSerial() {
  //Setup serial communication
  println(Serial.list());
  if (Serial.list().length > 0) {
    myPort = new Serial(this, Serial.list()[0], 9600);
    println("Port [0] selected for comms");
    myPort.bufferUntil('\n');
    myPort.clear();
    return true;
  } else {
    return false;
  }
}

public class PFrame extends JFrame {
  public PFrame(int width, int height) {
    setBounds(100, 100, width, height);
    sScreen = new SecondApplet();
    add(sScreen);
    sScreen.init();
    show();
  }
}

public class SecondApplet extends PApplet {
  int time = 0;
  int time1 = 0;
  int startTime, stopTime;
  int startTime1, stopTime1;
  int t0 = 0;
  int t1 = 0;
  int fontSize = 200;
  int fontSize1 = 100;
  PFont f, f1;
  boolean run = false;
  boolean run1 = false;
  boolean countUp = false;
  boolean showTimer = true;
  boolean showTimer1 = false;
  boolean timerSwap = false;

  public void setup() {
    background(0);
    noStroke();
    f = createFont("Arial Unicode MS", fontSize);
    f1 = createFont("Arial Unicode MS", fontSize1);
    textAlign(CENTER);
  }

  public void draw() {
    background(0);
    f = createFont("Arial Unicode MS", fontSize);
    f1 = createFont("Arial Unicode MS", fontSize1);
    textAlign(CENTER);
    textFont(f);
    textFont(f1);
    fontSize = width / 4;
    fontSize1 = width / 8;

    updateTimer();
    updateTimer1();
    if (showTimer) {
      textFont(f);
      if (timerSwap) {
        display(time1);
      } else {
        display(time);
      }
    }
    if (showTimer1) {
      textFont(f1);
      if (timerSwap) {
        display1(time);
      } else {
        display1(time1);
      }
    }
    if (checkForZero()) {
      timerSwap = false;
      hideTimer1();
    }
  }

  public void flash(char[] chars) {
    if (time1 <= 10000) {
      if (chars[4] == '1') {
        showTimer();
      } else if (chars[4] == '6') {
        hideTimer();
      }
    }
  }

  public void display1(int val) {
    fill(255);
    val = val / 10;
    char[] chars = millisToChar(val);
    String display = "" + chars[0] + chars[1] + ":" + chars[2] + chars[3] + ":" + chars[4] + chars [5];
    text(display, width/2, (height/5) + (fontSize1/3));
    flash(chars);
  }

  public void display(int val) { 
    fill(255);
    val = val / 10;
    char[] chars = millisToChar(val);
    String display = "" + chars[0] + chars[1] + ":" + chars[2] + chars[3] + ":" + chars[4] + chars [5];
    text(display, width/2, (height/2) + (fontSize/3));
  }

  public void updateTimer() {
    if (run) {
      time = t0 + millis() - startTime;
    }
  }

  public void updateTimer1() {
    if (run1) {
      if (countUp) {
        time1 = t1 + millis() - startTime1;
      } else if (!countUp) {
        time1 = t1 - (millis() - startTime1);
      }
    }
  }

  public boolean checkForZero() {
    if (time1 <= 0) {
      return true;
    } else { 
      return false;
    }
  }

  public void timerSwap() {
    timerSwap = true;
  }

  public void timerNotSwap() {
    timerSwap = false;
  }

  public void showTimer() {
    showTimer = true;
  }

  public void hideTimer() {
    showTimer = false;
  }

  public void showTimer1() {
    showTimer1 = true;
  }

  public void hideTimer1() {
    showTimer1 = false;
  }

  public void setTime1(int t) {
    time1 = t;
    t1 = t;
  }

  public void setTime(int t) {
    time = t;
  }

  public void startTimer() {
    if (!run) {
      run = true;
      startTime = millis();
    }
  }

  public void startTimer1() {
    if (!run1) {
      run1 = true;
      startTime1 = millis();
      //      println(startTime1);
      //      println(millis());
    }
  }

  public void stopTimer() {
    if (run) {
      run = false;
      stopTime = millis();
      t0 = time;
    }
  }

  public void stopTimer1() {
    if (run1) {
      run1 = false;
      stopTime1 = millis();
      t1 = time;
    }
  }

  public void resetTimer() {
    time = 0;
    startTime = millis();
    stopTime = 0;
    t0 = 0;
    time1 = 0;
    startTime1 = millis();
    stopTime1 = 0;
  }

  public void resetTimer1() {
    time1 = 0;
    startTime1 = millis();
    stopTime1 = 0;
  }

  public int getTime() {
    return time;
  }

  public char[] millisToChar(int micros) {

    char[] chars = new char[6];
    int minutes, seconds, msec;

    msec = micros % 100;
    minutes = (micros - msec) /  100 / 60;
    seconds = (micros - msec - (minutes * 60 * 100)) / 100;

    //    println(minutes + ":" + seconds + ":" + msec);

    String min = str(minutes);
    String sec = str(seconds);
    String mse = str(msec);

    if (minutes > 9) {
      chars[0] = min.charAt(0);
      chars[1] = min.charAt(1);
    } else {
      chars[0] = '0';
      chars[1] = min.charAt(0);
    }

    if (seconds > 9) {
      chars[2] = sec.charAt(0);
      chars[3] = sec.charAt(1);
    } else {
      chars[2] = '0';
      chars[3] = sec.charAt(0);
    }

    if (msec > 9) {
      chars[4] = mse.charAt(0);
      chars[5] = mse.charAt(1);
    } else {
      chars[4] = '0';
      chars[5] = mse.charAt(0);
    }

    return chars;
  }

  public char[] intToCharArray(int t) {
    String str = str(t);
    char[] chars = new char[6];

    for (int i = 0; i < chars.length; i++) {
      if (i < (chars.length - str.length())) {
        chars[i] = '0';
      } else {  
        chars[i] = str.charAt(i - (chars.length - str.length()));
      }
    }

    return chars;
  }
}
