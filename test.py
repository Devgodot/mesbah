import random

def create_maze(rows, cols):
    maze = [[1] * cols for _ in range(rows)]  # ابتدا همه خانه‌ها را دیوار در نظر بگیرید

    def dfs(row, col):
        maze[row][col] = 0  # خانه فعلی را به عنوان مسیر باز علامت گذاری کنید
        directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]  # جهت‌های حرکت
        random.shuffle(directions)  # جهت‌ها را به صورت تصادفی مرتب کنید

        for dr, dc in directions:
            nr, nc = row + dr, col + dc
            if 0 <= nr < rows and 0 <= nc < cols and maze[nr][nc] == 1:
                maze[nr][nc] = 0 # خانه مجاور را به عنوان مسیر باز علامت گذاری کنید
                dfs(nr, nc)

    dfs(rows - 1, 0)  # شروع از گوشه پایین سمت چپ

    # دیوارکشی بقیه خانه‌ها
    for i in range(rows):
        for j in range(cols):
            if maze[i][j] == 1:
                maze[i][j] = 1

    return maze

# ایجاد ماز 10x11
maze1 = create_maze(10, 11)
for row in maze1:
    print(row)

print("-" * 20)

# ایجاد ماز 11x10
maze2 = create_maze(11, 10)
for row in maze2:
    print(row)