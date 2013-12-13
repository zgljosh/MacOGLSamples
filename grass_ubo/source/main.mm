/*
 main
 
 Copyright 2012 Thomas Dalling - http://tomdalling.com/
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

// third-party libraries
#import <Foundation/Foundation.h>
#include <GL/glew.h>
#include <GL/glfw.h>
#include <glm/glm.hpp>
#include "vmath.h"
#include <sb6ktx.h>


// standard C++ libraries
#include <cassert>
#include <iostream>
#include <stdexcept>
#include <cmath>
#include <math.h>

// tdogl classes
#include "Program.h"

// constants
const glm::vec2 SCREEN_SIZE(800, 600);

// globals
tdogl::Program* gProgram = NULL;
GLuint gVAO = 0;
GLuint gVBO = 0;
GLuint buffers[1];

//GLuint uni2dloc;
GLuint uni1dloc;
GLuint      pallette_UniLoc=0;
GLuint      tex_grass_pallette; // unused !
GLuint      tex_grass_color;
GLuint      tex_grass_length;
GLuint      tex_grass_orientation;
GLuint      tex_grass_bend;
GLuint      pslloc;

static const int PAL_SIZE = 256;
GLfloat      tex_grass_colorArray[PAL_SIZE];

struct
{
    GLint   mvpMatrix;
} uniforms;

// returns the full path to the file `fileName` in the resources directory of the app bundle
static std::string ResourcePath(std::string fileName) {
    NSString* fname = [NSString stringWithCString:fileName.c_str() encoding:NSUTF8StringEncoding];
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fname];
    return std::string([path cStringUsingEncoding:NSUTF8StringEncoding]);
}


// loads the vertex shader and fragment shader, and links them to make the global gProgram
static void LoadShaders() {
    std::vector<tdogl::Shader> shaders;
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("vertex-shader.txt"), GL_VERTEX_SHADER));
    //shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("fragment-shader.txt"), GL_FRAGMENT_SHADER));
    // enable color change with fragment position
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("frag-shader-color-vary.txt"), GL_FRAGMENT_SHADER));
    gProgram = new tdogl::Program(shaders);
}

static void loadTex()
{    pallette_UniLoc = glGetUniformLocation(gProgram->object(), "pal_texture");
    uni1dloc = glGetUniformLocation(gProgram->object(), "uni1d");
    
    uniforms.mvpMatrix = glGetUniformLocation(gProgram->object(), "mvpMatrix");
pslloc = glGetUniformLocation(gProgram->object(), "pal_texture");
    tex_grass_color = glGetUniformLocation(gProgram->object(), "grasscolor_texture");
    tex_grass_length = glGetUniformLocation(gProgram->object(), "length_texture");
    tex_grass_orientation = glGetUniformLocation(gProgram->object(), "orientation_texture");
    tex_grass_bend = glGetUniformLocation(gProgram->object(), "bend_texture");

    //uni2dloc = glGetUniformLocation(gProgram->object(), "uni2d");
    
    //
    std::string path2ktx = "/Users/mc309/test/glModern/sb6code/bin/media/textures_packages2/";
    glActiveTexture(GL_TEXTURE1);
    sb6::ktx::file::load(path2ktx.append("grass_length.ktx").data(), 1);
    glUniform1i(tex_grass_length, 1);
    
    glActiveTexture(GL_TEXTURE2);
    path2ktx = "/Users/mc309/test/glModern/sb6code/bin/media/textures_packages2/";
    sb6::ktx::file::load(path2ktx.append("grass_orientation.ktx").data(), 2);
    glUniform1i(tex_grass_orientation, 2);
    
    glActiveTexture(GL_TEXTURE3);
    path2ktx = "/Users/mc309/test/glModern/sb6code/bin/media/textures_packages2/";
    sb6::ktx::file::load(path2ktx.append("grass_color.ktx").data(), 3);
    glUniform1i(tex_grass_color, 3);
    
    glActiveTexture(GL_TEXTURE4);
    path2ktx = "/Users/mc309/test/glModern/sb6code/bin/media/textures_packages2/";
    sb6::ktx::file::load(path2ktx.append("grass_bend.ktx").data(), 4);
    glUniform1i(tex_grass_bend, 4);
    
    for(int i = 0; i < PAL_SIZE; i++)
    {tex_grass_colorArray[i] =i *0.003;    }
    
    ///glEnable(GL_TEXTURE_1D);

//    glTexStorage1D(GL_TEXTURE_1D, h.miplevels, h.glinternalformat, h.pixelwidth);
//    glTexSubImage1D(GL_TEXTURE_1D, 0, 0, h.pixelwidth, h.glformat, h.glinternalformat, data);
//    break;
    //glActiveTexture(GL_TEXTURE0);//
//    glGenTextures(1, &tex_grass_pallette);
//    glBindTexture(GL_TEXTURE_1D, tex_grass_pallette);
//    glTexStorage1D(GL_TEXTURE_1D, 8, GL_R8, PAL_SIZE);
//    glTexImage1D(GL_TEXTURE_1D, 0, GL_R8, PAL_SIZE, 0,
//                    GL_RED, GL_UNSIGNED_BYTE, &tex_grass_colorArray[0]);
//    //glTexStorage1D(GL_TEXTURE_1D, 8, GL_R8, PAL_SIZE);
//    //glTexSubImage1D(GL_TEXTURE_1D, 0, 0, PAL_SIZE, GL_R8, GL_UNSIGNED_BYTE, tex_grass_colorArray);
////    glGenerateMipmap(GL_TEXTURE_1D);
//    glUniform1i(17, tex_grass_pallette);
}

// loads a triangle into the VAO global
static void LoadTriangle() {
    static const GLfloat grass_blade[] =
    {
        -0.3f, 0.0f,
        0.3f, 0.0f,
        -0.20f, 1.0f,
        0.1f, 1.3f,
        -0.05f, 2.3f,
        0.0f, 3.3f
    };
    
    glGenVertexArrays(1, &gVAO);
    glGenBuffers(1, &buffers[0]);
    glBindVertexArray(gVAO);
    glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(grass_blade), grass_blade, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glEnableVertexAttribArray(0);
    
    // unbind the VBO and VAO
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}


static void Render(double currentTime) {
    float t = (float)currentTime * 0.02f;
    float r = 550.0f;
    
    static const GLfloat black[] = { 0.0f, 0.0f, 0.0f, 1.0f };
    static const GLfloat one = 1.0f;
    glClearBufferfv(GL_COLOR, 0, black);
    glClearBufferfv(GL_DEPTH, 0, &one);
    
    vmath::mat4 mv_matrix = vmath::lookat(vmath::vec3(sinf(t) * r, 25.0f, cosf(t) * r),
                                          vmath::vec3(0.0f, -50.0f, 0.0f),
                                          vmath::vec3(0.0, 1.0, 0.0));
    vmath::mat4 prj_matrix = vmath::perspective(45.0f, (float)SCREEN_SIZE.x / (float)SCREEN_SIZE.y, 0.1f, 1000.0f);
    
    glUseProgram(gProgram->object());
    glUniformMatrix4fv(uniforms.mvpMatrix, 1, GL_FALSE, (prj_matrix * mv_matrix));
        glUniform1fv(uni1dloc, PAL_SIZE, tex_grass_colorArray);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    glViewport(0, 0, SCREEN_SIZE.x, SCREEN_SIZE.y);
    
    glBindVertexArray(gVAO);
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 6, 1024 * 1024);
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);
    
    // unbind the VAO
    glBindVertexArray(0);
    
    // unbind the program
    glUseProgram(0);
    
    // swap the display buffers (displays what was just drawn)
    glfwSwapBuffers();
}

void shutdown()
{
    glDeleteVertexArrays(1, &gVAO);
    glDeleteProgram(gProgram->object());
    //glDeleteBuffers(1, &buffer); ???
}

// the program starts here
void AppMain() {
    // initialise GLFW
    if(!glfwInit())
        throw std::runtime_error("glfwInit failed");
    
    // open a window with GLFW
    glfwOpenWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwOpenWindowHint(GLFW_OPENGL_VERSION_MAJOR, 3);
    glfwOpenWindowHint(GLFW_OPENGL_VERSION_MINOR, 2);
    glfwOpenWindowHint(GLFW_WINDOW_NO_RESIZE, GL_TRUE);
    if(!glfwOpenWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, 8, 8, 8, 8, 0, 0, GLFW_WINDOW))
        throw std::runtime_error("glfwOpenWindow failed. Can your hardware handle OpenGL 3.2?");
    
    // initialise GLEW
    glewExperimental = GL_TRUE; //stops glew crashing on OSX :-/
    if(glewInit() != GLEW_OK)
        throw std::runtime_error("glewInit failed");
    
    // print out some info about the graphics drivers
    std::cout << "OpenGL version: " << glGetString(GL_VERSION) << std::endl;
    std::cout << "GLSL version: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;
    std::cout << "Vendor: " << glGetString(GL_VENDOR) << std::endl;
    std::cout << "Renderer: " << glGetString(GL_RENDERER) << std::endl;
    
    // make sure OpenGL version 3.2 API is available
    if(!GLEW_VERSION_4_1)
        throw std::runtime_error("OpenGL 4.1 API is not available.");

    // load vertex and fragment shaders into opengl
    LoadShaders();
    loadTex();
    // create buffer and fill it with the points of the triangle
    LoadTriangle();
    glValidateProgram(gProgram->object());
    
    // run while the window is open
    while(glfwGetWindowParam(GLFW_OPENED)){
        // draw one frame
        Render(glfwGetTime());
    }
    
    shutdown();
    
    // clean up and exit
    glfwTerminate();
}

int main(int argc, char *argv[]) {
    try {
        AppMain();
    } catch (const std::exception& e){
        std::cerr << "ERROR: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}

