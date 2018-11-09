APP = velvet-1.2.10
EMAIL = kyclark@email.arizona.edu
SINGULARITY = /usr/local/bin/singularity
IMG = $(APP).img
DEF = image.def

img:
	#rm -f $(IMG)
	#sudo $(SINGULARITY) create --size 1024 $(IMG)
	#sudo $(SINGULARITY) bootstrap $(IMG) $(DEF)
	sudo $(SINGULARITY) build -s $(IMG) $(DEF)

run:
	$(SINGULARITY) run $(IMG)

shell:
	sudo $(SINGULARITY) shell --writable -s /bin/bash -B $(PWD):/home $(IMG) 

test:
	$(SINGULARITY) run -B $(PWD):/work -W /work $(IMG) -d data -o velvet-out
