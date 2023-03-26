# Sokoban

## Prerequisites
- NetLogo

## Project structure
- report.ipynb
- report.html - built report (just open it in the browser)
- **VIA_with_teleports.nlogo** - model with implemented teleports, but without the box
- game_repr.csv, value_iter_exper.csv - CSV files generated using Behavior Space
- static/ - folder containing .html files with graphs (needed for correct display of report.html)

- **VIA_with_teleports_and_sokoban.nlogo** - the final model with implemented player, box, teleports and value iteration.
- 

## Usage of **VIA_with_teleports_and_sokoban.nlogo**
1. Press "setup"
2. Choose the initial box position and the exit for box using the corresponding sliders.
3. Press "update-box"
4. Specify parameters epsilon and gamma and press "value-iteration" to perform value iteration.
5. Wait until the value iteration algorithm terminates. Halt if you want to stop it.
6. Use "go once" to see how the turtle moves the box.

Here is a video how my turtle performs after approx. 30 minutes of value-iteration with epsilon=0.01 and gamma=0.95:

<video src='./sokoban_example.mp4'/>


