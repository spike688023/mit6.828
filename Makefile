default: run

build:
	docker build -t spike688023/xv6 .

rebuild:
	docker build --no-cache -t spike688023/xv6 .

run:
	docker run -i --name xv6 -v /root/grantbox_xv6/MIT:/home/a/MIT -d -t spike688023/xv6 
	#docker run -i --name xv6 -v "$(PWD)"/MIT:/home/a/MIT -d -t spike688023/xv6 

shell:
	docker exec -it xv6 bash -l

logs:
	docker logs xv6 

rm:
	docker rm -f xv6
