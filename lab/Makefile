.PHONY: image run

image:
	@echo "Building lab image"
	docker build -t lab_image:test .

run:
	@echo "Building lab image"
	docker run --rm -p 8888:8888 --mount "type=bind,source=/data,target=/data" lab_image:test
