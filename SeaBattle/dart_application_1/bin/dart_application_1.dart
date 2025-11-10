import 'dart:io';
import 'dart:math';

const int size = 10;
const List<int> shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

class SeaBattle {
  List<List<String>> playerField = List.generate(
    size,
    (_) => List.filled(size, '·'),
  );
  List<List<String>> aiField = List.generate(
    size,
    (_) => List.filled(size, '·'),
  );
  List<List<String>> aiHidden = List.generate(
    size,
    (_) => List.filled(size, '·'),
  );

  Random random = Random();
  int playerScore = 0;
  int aiScore = 0;

  void start() {
    print('==== МОРСКОЙ БОЙ ====');
    print('1. Автоматическая расстановка кораблей');
    print('2. Ручная расстановка');
    stdout.write('Выберите режим: ');
    int choice = int.tryParse(stdin.readLineSync() ?? '') ?? 1;

    if (choice == 1) {
      autoPlaceShips(playerField);
    } else {
      manualPlacement(playerField);
    }
    autoPlaceShips(aiField);
    gameLoop();
  }

  void manualPlacement(List<List<String>> field) {
    print('Расставляем корабли вручную.');
    for (int ship in shipSizes) {
      bool placed = false;
      while (!placed) {
        printField(field);
        print(
          'Введите координаты и направление (например, "A5 H" или "C3 V") для корабля длиной $ship:',
        );
        String? input = stdin.readLineSync();
        if (input == null || input.isEmpty) continue;
        input = input.toUpperCase().replaceAll(' ', '');
        if (input.length < 3) continue;
        int x = input.codeUnitAt(0) - 65;
        int y = int.tryParse(input.substring(1, input.length - 1)) ?? -1;
        String dir = input[input.length - 1];
        placed = placeShip(field, x, y - 1, ship, dir == 'H');
        if (!placed) print('Нельзя поставить корабль здесь. Попробуйте снова.');
      }
    }
  }

  bool placeShip(
    List<List<String>> field,
    int x,
    int y,
    int length,
    bool horizontal,
  ) {
    if (x < 0 || y < 0 || x >= size || y >= size) return false;
    if (horizontal) {
      if (x + length > size) return false;
    } else {
      if (y + length > size) return false;
    }

    // Проверка на буфер вокруг корабля (1 клетка пустая со всех сторон)
    for (int i = 0; i < length; i++) {
      int nx = x + (horizontal ? i : 0);
      int ny = y + (horizontal ? 0 : i);
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          int cx = nx + dx;
          int cy = ny + dy;
          if (cx >= 0 && cx < size && cy >= 0 && cy < size) {
            if (field[cy][cx] == '■') return false;
          }
        }
      }
    }

    // Размещение корабля
    for (int i = 0; i < length; i++) {
      int nx = x + (horizontal ? i : 0);
      int ny = y + (horizontal ? 0 : i);
      field[ny][nx] = '■';
    }

    return true;
  }

  void autoPlaceShips(List<List<String>> field) {
    for (int ship in shipSizes) {
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 1000) {
        int x = random.nextInt(size);
        int y = random.nextInt(size);
        bool horizontal = random.nextBool();
        placed = placeShip(field, x, y, ship, horizontal);
        attempts++;
      }
      if (!placed) {
        field = List.generate(size, (_) => List.filled(size, '·'));
        autoPlaceShips(field);
        return;
      }
    }
  }

  void gameLoop() {
    print('\nИгра начинается!');
    bool gameOver = false;

    while (!gameOver) {
      print('\nВаше поле:');
      printField(playerField);
      print('\nПоле врага:');
      printField(aiHidden);

      print('\nВаш ход (например: A5):');
      String? move = stdin.readLineSync();
      if (move == null || move.isEmpty) continue;
      move = move.toUpperCase();
      int x = move.codeUnitAt(0) - 65;
      int y = int.tryParse(move.substring(1)) ?? 0;
      if (x < 0 || x >= size || y < 1 || y > size) {
        print('Неверные координаты.');
        continue;
      }

      String result = playerShot(x, y - 1);
      print(result);

      if (playerScore == totalShipCells()) {
        print('Вы победили!');
        gameOver = true;
        break;
      }

      aiTurn();

      if (aiScore == totalShipCells()) {
        print('Компьютер победил!');
        gameOver = true;
      }
    }

    print('\nИгра окончена.');
    print('Ваш счёт: $playerScore | Компьютер: $aiScore');
  }

  int totalShipCells() => shipSizes.reduce((a, b) => a + b);

  String playerShot(int x, int y) {
    if (aiHidden[y][x] != '·') return 'Вы уже стреляли сюда.';

    if (aiField[y][x] == '■') {
      aiField[y][x] = 'X';
      aiHidden[y][x] = 'X';
      playerScore++;
      return isShipDestroyed(aiField, x, y)
          ? 'Уничтожен корабль!'
          : 'Попадание!';
    } else {
      aiHidden[y][x] = '○';
      return 'Мимо.';
    }
  }

  bool isShipDestroyed(List<List<String>> field, int x, int y) {
    List<List<int>> dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];

    for (var dir in dirs) {
      int nx = x + dir[0];
      int ny = y + dir[1];
      while (nx >= 0 && nx < size && ny >= 0 && ny < size) {
        if (field[ny][nx] == '■') return false;
        if (field[ny][nx] == '·' || field[ny][nx] == '○') break;
        nx += dir[0];
        ny += dir[1];
      }
    }
    return true;
  }

  void aiTurn() {
    bool valid = false;
    while (!valid) {
      int x = random.nextInt(size);
      int y = random.nextInt(size);
      if (playerField[y][x] == '■') {
        playerField[y][x] = 'X';
        print('Компьютер попал в (${String.fromCharCode(x + 65)}${y + 1})!');
        aiScore++;
        if (isShipDestroyed(playerField, x, y)) {
          print('Компьютер уничтожил ваш корабль!');
        }
        valid = true;
      } else if (playerField[y][x] == '·') {
        playerField[y][x] = '○';
        print(
          'Компьютер промахнулся (${String.fromCharCode(x + 65)}${y + 1}).',
        );
        valid = true;
      }
    }
  }

  void printField(List<List<String>> field) {
    stdout.write('   ');
    for (int i = 0; i < size; i++) {
      stdout.write('${String.fromCharCode(65 + i)} ');
    }
    print('');
    for (int i = 0; i < size; i++) {
      stdout.write('${(i + 1).toString().padLeft(2)} ');
      for (int j = 0; j < size; j++) {
        stdout.write('${field[i][j]} ');
      }
      print('');
    }
  }
}

void main() {
  SeaBattle game = SeaBattle();
  game.start();
}
