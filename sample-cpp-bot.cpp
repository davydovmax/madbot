#include <iostream>
#include <algorithm>
#include <vector>
#include <string>
#include <ctime>

using namespace std;

class Point {
public:
	int x;
	int y;
};

class Player : public Point {
public:
	string name;
	int id;
	int snippets;
	bool has_weapon;
	bool is_paralyzed;
};

int width;
int height;
vector<vector<int> > is_wall;
int timebank;
int time_per_move;
int time_remaining;
int max_rounds;
int current_round;
Player me;
Player enemy;
vector<Point> snippets;
vector<Point> weapons;
vector<Point> bugs;

void do_move();

void process_next_command() {
	string command;
	cin >> command;
	if (command == "settings") {
		string type;
		cin >> type;
		if (type == "timebank") {
			cin >> timebank;
		}
		else if (type == "time_per_move") {
			cin >> time_per_move;
		}
		else if (type == "player_names") {
			string names;
			cin >> names;
			// player names aren't very useful
		}
		else if (type == "your_bot") {
			cin >> me.name;
		}
		else if (type == "your_botid") {
			cin >> me.id;
		}
		else if (type == "field_width") {
			cin >> width;
		}
		else if (type == "field_height") {
			cin >> height;
		}
		else if (type == "max_rounds") {
			cin >> max_rounds;
		}
	}
	else if (command == "update") {
		string player_name, type;
		cin >> player_name >> type;
		if (type == "round") {
			cin >> current_round;
		}
		else if (type == "field") {
			snippets.clear();
			weapons.clear();
			bugs.clear();
			is_wall.clear();
			for (int x = 0; x < height; x++) {
				is_wall.push_back(vector<int>(width));
			}
			string s;
			cin >> s;
			int n = s.length();
			int i = 0;
			for (int x = 0; x < height; x++) {
				for (int y = 0; y < width; y++) {
					Point pt;
					pt.x = x;
					pt.y = y;
					while (true) {
						if (i == n || s[i] == ',') {
							i++;
							break;
						}
						char c = s[i++];
						if (c == 'x') {
							is_wall[x][y] = 1;
						}
						else if (c == '.') {
							//do nothing, is_wall[x][y] == 0 by default
						}
						else if (c == 'E') {
							bugs.push_back(pt);
						}
						else if (c == 'W') {
							weapons.push_back(pt);
						}
						else if (c == 'C') {
							snippets.push_back(pt);
						}
						else {
							// played id
							int id = c - '0';
							if (id == me.id) {
								me.x = x;
								me.y = y;
							}
							else {
								enemy.x = x;
								enemy.y = y;
							}
						}
					}
				}
			}
		}
		else if (type == "snippets") {
			if (player_name == me.name) {
				cin >> me.snippets;
			}
			else {
				cin >> enemy.snippets;
			}
		}
		else if (type == "has_weapon") {
			string value;
			cin >> value;
			if (player_name == me.name) {
				me.has_weapon = (value == "true");
			}
			else {
				enemy.has_weapon = (value == "true");
			}
		}
		else if (type == "is_paralyzed") {
			string value;
			cin >> value;
			if (player_name == me.name) {
				me.is_paralyzed = (value == "true");
			}
			else {
				enemy.is_paralyzed = (value == "true");
			}
		}
	}
	else if (command == "action") {
		string useless_move;
		cin >> useless_move;
		cin >> time_remaining;
		do_move();
	}
}

int main() {
	srand((int)time(0));
	while (true) {
		process_next_command();
	}
	return 0;
}

//-----------------------------------------//
//  Improve the code below to win 'em all  //
//-----------------------------------------//

int dx[4] = { -1,0,1,0 };
int dy[4] = { 0,-1,0,1 };
string moves[4] = { "up", "left", "down", "right" };

void do_move() {
	vector<string> valid_moves;
	for (int dir = 0; dir < 4; dir++) {
		int nextx = me.x + dx[dir];
		int nexty = me.y + dy[dir];
		if (nextx >= 0 && nextx < height && nexty >= 0 && nexty < width) {
			if (!is_wall[nextx][nexty]) {
				valid_moves.push_back(moves[dir]);
			}
		}
	}
	if (valid_moves.size() == 0) {
		valid_moves.push_back("pass");
	}
	cout << valid_moves[rand() % valid_moves.size()] << endl;
}