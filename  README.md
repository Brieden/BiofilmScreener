# Screening for physical and biological determinants of bacterial swarm development

Masters degree research project, supervised by Prof. Dr Knut Drescher. Planning and implementing a robot for screening for physical and biological determinants of swarm development. Developed and apply biology High-Throughput techniques to transform a single deletion mutant library into another strain background. Create an image analysis to characterize bacteria growing phenotypes.

You can find my presentation with all videos here:
https://docs.google.com/presentation/d/1tqcbO8-vWdntdbicMGbfJU4cljr4m9Nmk_LXXtKPaSw/edit?usp=sharing


Most of the components during an experiment, like motors and camera, are managed via a user interface on
a computer. The difficulty in the development was the stability of the system, which has to run for several hours without human intervention.
For the first iterations, Python 3.7 and digiCamControl v2.1.2 were used for controlling the robot. However, this was replaced by Matlab r2018b and micromanager 2.0.0-beta3 20181129 for a better integration with the existing software ecosystem. The control of the motors and the read-out of the light barriers states are carried out by two microcontrollers, programmed in the C++ programming language.
The GUI (Graphical User Interface) for controlling the robot is called BiofilmScreener_controll_center.
Konstantin Neuhaus created the front end. The control of the motors is taken over by Robot_class.m.

I am happy to assist you with any questions.


