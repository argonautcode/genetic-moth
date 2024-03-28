import java.util.Random;
import java.util.Arrays;

final color BACKGROUND = #757f49;
final color BORDER = #665329;
final color HIGHLIGHT = #c7cbb6;
final color TEXT_COLOR = #2a291e;
final color TEXT_IMP = #906b16;
PFont TITLE_FONT;
PFont SUB_FONT;
PFont TEXT_FONT;

final int GRID_LEN = 32;
final float MUTATION_RATE = 0.01;

int[] grid = new int[GRID_LEN * GRID_LEN];
int[] animgrid = new int[GRID_LEN * GRID_LEN];
float treeColor = 128;
// float treeColor = noise(0) * 255;
int[] distr = new int[256];
ArrayList<Float> avg = new ArrayList<>();
ArrayList<Float> tree = new ArrayList<>();
int gen = 1;
boolean updated = true;
boolean animated = true;
boolean taskDone = false;
int step = 0;
int startFrame = 0;

void resetAnimGrid() {
  for (int i = 0; i < GRID_LEN * GRID_LEN; i++) {
    animgrid[i] = i;
  }
}

void calcDistr() {
  for (int i = 0; i < 256; i++) {
    distr[i] = 0;
  }
  for (int i = 0; i < grid.length; i++) {
    distr[grid[i]] ++;
  }
}

float calcAvg() {
  int sum = 0;
  for (int i = 0; i < grid.length; i++) {
    sum += grid[i];
  }
  return ((float) sum) / (GRID_LEN * GRID_LEN);
}

void drawTree(int x, int y, int s, int ss) {
  int treeLength = s * GRID_LEN + ss * (GRID_LEN + 1) + 8;
  stroke(BORDER);
  strokeWeight(8);
  fill(treeColor);
  rect(x + 4, y + 4, treeLength, treeLength);
  int offset = 8 + ss;
  noStroke();
  for (int i = 0; i < GRID_LEN; i++) {
    for (int j = 0; j < GRID_LEN; j++) {
      fill(grid[i + j * GRID_LEN]);
      rect(x + (s + ss) * i + offset, y + (s + ss) * j + offset, s, s);
    }
  }
}

void drawAnimSortTree(int x, int y, int s, int ss, float l) {
  int treeLength = s * GRID_LEN + ss * (GRID_LEN + 1) + 8;
  stroke(BORDER);
  strokeWeight(8);
  fill(treeColor);
  rect(x + 4, y + 4, treeLength, treeLength);
  int offset = 8 + ss;
  noStroke();
  for (int di = 0; di < GRID_LEN; di++) {
    for (int dj = 0; dj < GRID_LEN; dj++) {
      int j = animgrid[di + dj * GRID_LEN] / GRID_LEN;
      int i = animgrid[di + dj * GRID_LEN] - j * GRID_LEN;
      fill(grid[i + j * GRID_LEN]);
      rect(x + (s + ss) * lerp(i, di, l) + offset, y + (s + ss) * lerp(j, dj, l) + offset, s, s);
    }
  }
}

void drawLineGraph(int x, int y, ArrayList<Float> avg, ArrayList<Float> tree) {
  stroke(BORDER);
  strokeWeight(8);
  fill(HIGHLIGHT);
  rect(x + 4, y + 4, 1052, 552);
  textFont(SUB_FONT);
  fill(TEXT_COLOR);
  text("Average Color", x + 530, y + 54);
  textFont(TEXT_FONT);
  text("0", x + 35, y + 530);
  text("255", x + 35, y + 105);
  fill(TEXT_IMP);
  text("Target Color: " + (int) treeColor, x + 150, y + 50);
  noFill();
  strokeWeight(4);
  stroke(TEXT_IMP);
  beginShape();
  for (int i = 0; i < tree.size(); i++) {
    vertex(x + 70 + (965.0 / (tree.size() - 1)) * i, y + 530 - 425 * (tree.get(i) / 255.0));
  }
  endShape();
  stroke(TEXT_COLOR);
  beginShape();
  for (int i = 0; i < avg.size(); i++) {
    vertex(x + 70 + (965.0 / (avg.size() - 1)) * i, y + 530 - 425 * (avg.get(i) / 255.0));
  }
  endShape();
}

void drawHistogram(int x, int y, int[] distr) {
  stroke(BORDER);
  strokeWeight(8);
  fill(HIGHLIGHT);
  rect(x + 4, y + 4, 1052, 552);
  textFont(SUB_FONT);
  fill(TEXT_COLOR);
  text("Color Distribution", x + 530, y + 54);
  noStroke();
  fill(TEXT_IMP);
  rect(x + treeColor * 4 + 18, y + 124, 4, 400);
  textFont(TEXT_FONT);
  text("Target Color", max(min(x + treeColor * 4 + 18, x + 955), 170), y + 104);
  fill(TEXT_COLOR);
  for (int i = 0; i < distr.length; i++) {
    rect(x + i * 4 + 18, y + 524 - 12 * sqrt(distr[i]), 4, 12 * sqrt(distr[i]));
  }
  text("0", x + 25, y + 538);
  text("255", x + 1020, y + 538);
}

void setup() {
  fullScreen();
  frameRate(60);
  TITLE_FONT = loadFont("JetBrainsMonoSlashed-Regular-96.vlw");
  SUB_FONT = loadFont("JetBrainsMonoSlashed-Regular-48.vlw");
  TEXT_FONT = loadFont("JetBrainsMonoSlashed-Regular-24.vlw");
  textAlign(CENTER, CENTER);

  // Randomly initialize grid
  Random random = new Random();
  for (int i = 0; i < grid.length; i++) {
    grid[i] = Math.abs(random.nextInt()) % 256;
  }
  resetAnimGrid();

  avg.add(calcAvg());
  tree.add(treeColor);
  calcDistr();
}

void draw() {
  if (!animated) {
    if (!updated) {
      // Perform selection
      Integer[] sorted = Arrays.stream(grid).boxed().toArray(Integer[]::new);
      Arrays.sort(sorted, (a, b) -> (int) (Math.abs(treeColor - a) - Math.abs(treeColor - b)));
      grid = Arrays.stream(sorted).mapToInt(Integer::intValue).toArray();

      // Perform mutation
      for (int i = 0, l = grid.length / 2; i < l; i++) {
        grid[i + l] = grid[i];
        for (int k = 0; k < 8; k++) {
          if (Math.random() < MUTATION_RATE) {
            grid[i + l] = grid[i + l] ^ (1 << k);
          }
        }
      }

      // treeColor = (int) ((sin((PI / 128.0) * gen) + 1) * 127.5);
      treeColor = (int) (noise(gen / 128.0) * 255);
      avg.add(calcAvg());
      tree.add(treeColor);
      calcDistr();

      gen++;
      updated = true;
    }
    if (updated && gen < 1024) {
      updated = false;
    }

    // Draw UI
    background(BACKGROUND);
    textFont(TITLE_FONT);
    fill(TEXT_COLOR);
    text("Generation " + gen, 593, 100);
    drawTree(1188, 68, 32, 8);
    drawLineGraph(68, 192, avg, tree);
    drawHistogram(68, 812, distr);
  } else {
    background(BACKGROUND);
    textFont(TITLE_FONT);
    if (step == 0) {
      fill(TEXT_COLOR);
      text("Generation " + gen + "\n", 593, height/2);
      drawTree(1188, 68, 32, 8);
    } else if (step == 1) {
      // Perform animated selection
      if (!taskDone) {
        resetAnimGrid();
        Integer[] sorted = Arrays.stream(animgrid).boxed().toArray(Integer[]::new);
        Arrays.sort(sorted, (a, b) -> (int) (Math.abs(treeColor - grid[a]) - Math.abs(treeColor - grid[b])));
        animgrid = Arrays.stream(sorted).mapToInt(Integer::intValue).toArray();
        startFrame = frameCount;
        taskDone = true;
      }

      fill(TEXT_COLOR);
      text("Generation " + gen + "\n", 593, height/2);
      drawAnimSortTree(1188, 68, 32, 8, min((frameCount - startFrame) / 150.0, 1.0));
    } else if (step == 2) {
      if (taskDone) {
        Integer[] sorted = Arrays.stream(grid).boxed().toArray(Integer[]::new);
        Arrays.sort(sorted, (a, b) -> (int) (Math.abs(treeColor - a) - Math.abs(treeColor - b)));
        grid = Arrays.stream(sorted).mapToInt(Integer::intValue).toArray();
        startFrame = frameCount;
        taskDone = false;
      }

      fill(TEXT_COLOR);
      text("Generation " + gen + "\n", 593, height/2);
      drawTree(1188, 68, 32, 8);
      fill(treeColor, min((frameCount - startFrame) / 60.0, 1.0) * 255);
      rect(1196, 76+644, 1288, 644);
    } else if (step == 3) {
      // Perform mutation
      if (!taskDone) {
        for (int i = 0, l = grid.length / 2; i < l; i++) {
          grid[i + l] = grid[i];
          for (int k = 0; k < 8; k++) {
            if (Math.random() < MUTATION_RATE) {
              grid[i + l] = grid[i + l] ^ (1 << k);
            }
          }
        }
        startFrame = frameCount;
        taskDone = true;
      }
      fill(TEXT_COLOR);
      text("Generation " + gen + "\n", 593, height/2);
      drawTree(1188, 68, 32, 8);
      fill(treeColor, 255 - min((frameCount - startFrame) / 60.0, 1.0) * 255);
      rect(1196, 76+644, 1288, 644);
    }
  }
}

void mouseClicked() {
  if (!animated && updated) {
    updated = false;
  }
  if (animated) {
    if (step == 3) {
      step = 1;
      gen++;
      taskDone = false;
    } else {
      step ++;
    }
  }
}
