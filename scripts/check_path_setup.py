import os
import sys


def main():
    env_path = os.environ.get('PATH')

    found = False
    for path in env_path.split(':'):
        if path == "/usr/bin":
            break
        if path == "/usr/local/bin":
            found = True
            break
    if not found:
        sys.exit(1)
    sys.exit(0)



if __name__ == "__main__":
    main()
