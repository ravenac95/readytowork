import sys
from requests import ConnectionError
from docker import Client


def main():
    docker_client = Client()
    try:
        docker_client.images()
    except ConnectionError:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
