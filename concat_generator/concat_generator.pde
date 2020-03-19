
// Points at a folder, and generates the ffmpeg concat call for files with different codecs: https://trac.ffmpeg.org/wiki/Concatenate#differentcodec
// Started from https://processing.org/examples/directorylist.html

import java.util.Date;

String[] VIDEO_EXTENSIONS = new String[]{ "mp4" };


void setup() {

  // Using just the path of this sketch to demonstrate,
  // but you can list any directory you like.
  //String path = sketchPath();
  selectFolder("Select a folder to process:", "folderSelected");

  noLoop();
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
  }
  
  String path = selection.getAbsolutePath();
  
  println("Listing all filenames in a directory: ");
  //String[] filenames = listFileNames(path);
  String[] filenames = listFileNamesFiltered(path, new ExtensionFilter(VIDEO_EXTENSIONS));
  printArray(filenames);
  
  // For a simple three file, the call would look like this:
  // $ ffmpeg -i 01.mp4 -i 02.mp4 -i 03.mp4 -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0][2:v:0][2:a:0]concat=n=3:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" output.mp4
  String bash = "ffmpeg";
  for (int i = 0; i < filenames.length; i++) {
    bash += " -i " + filenames[i];
  }
  
  bash += " -filter_complex \"";
  for (int i = 0; i < filenames.length; i++) {
    //bash += "[" + i + ":v:0][" + i + ":a:0]";
    //bash += "[" + i + ":0][" + i + ":1]";
    bash += "[" + i + ":v][" + i + ":a]";
  }
  
  bash += "concat=n=" + filenames.length + ":v=1:a=1[outv][outa]\" -map \"[outv]\" -map \"[outa]\" concat.mp4";
  
  String[] lines = new String[1];
  lines[0] = bash;
  saveStrings("concat.bat", lines);
}



// Nothing is drawn in this program and the draw() doesn't loop because
// of the noLoop() in setup()
void draw() {
}

// This function returns all the files in a directory as an array of Strings  
String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

// Same thing, but filtered by extension. 
String[] listFileNamesFiltered(String dir, FileFilter filter) {
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles(filter);
    String[] fileNames = new String[files.length];
    for (int i = 0; i < files.length; i++) {
      fileNames[i] = files[i].getName();
    }
    return fileNames;
  } else {
    return null;
  } 
}

// This function returns all the files in a directory as an array of File objects
// This is useful if you want more info about the file
File[] listFiles(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } else {
    // If it's not a directory
    return null;
  }
}

// Function to get a list of all files in a directory and all subdirectories
ArrayList<File> listFilesRecursive(String dir) {
  ArrayList<File> fileList = new ArrayList<File>(); 
  recurseDir(fileList, dir);
  return fileList;
}

// Recursive function to traverse subdirectories
void recurseDir(ArrayList<File> a, String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    // If you want to include directories in the list
    a.add(file);  
    File[] subfiles = file.listFiles();
    for (int i = 0; i < subfiles.length; i++) {
      // Call this function on all files in this directory
      recurseDir(a, subfiles[i].getAbsolutePath());
    }
  } else {
    a.add(file);
  }
}






// A FileFilter by file extension.
// https://alvinalexander.com/blog/post/java/how-implement-java-filefilter-list-files-directory
import java.io.*;

public class ExtensionFilter implements FileFilter 
{
  private final String[] extensions;
  
  public ExtensionFilter(String[] fileExtensions) {
    this.extensions = fileExtensions;
  }
     
  public boolean accept(File file)
  {
    String fext = file.getName().toLowerCase();
    for (String extension : this.extensions)
    {
      if (fext.endsWith(extension))
      {
        return true;
      }
    }
    return false;
  }
  
}
