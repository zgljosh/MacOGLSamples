/*
 
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

// standard C++ libraries
#include <cassert>
#include <iostream>
#include <stdexcept>
#include <cmath>
#include <math.h>
#include "vmath.h"

// tdogl classes
#include "Program.h"

#define BREATHING_BG
#define MANY_CUBES

// constants
const glm::vec2 SCREEN_SIZE(800, 600);

// globals
tdogl::Program* gProgram = NULL;
GLuint gVAO = 0;
GLuint gVBO = 0;
GLuint          buffer;
GLint           mv_location;
GLint           proj_location;

//GLuint position_buffer;
//GLuint index_buffer;

float           aspect;
vmath::mat4     proj_matrix;

// returns the full path to the file `fileName` in the resources directory of the app bundle
static std::string ResourcePath(std::string fileName) {
    NSString* fname = [NSString stringWithCString:fileName.c_str() encoding:NSUTF8StringEncoding];
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fname];
    return std::string([path cStringUsingEncoding:NSUTF8StringEncoding]);
}

void onResize(int w, int h)
{
    aspect = (float)w / (float)h;
    proj_matrix = vmath::perspective(50.0f, aspect, 0.1f, 1000.0f);
}

// loads the vertex shader and fragment shader, and links them to make the global gProgram
static void LoadShaders() {
    std::vector<tdogl::Shader> shaders;
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("v1.txt"), GL_VERTEX_SHADER));
    shaders.push_back(tdogl::Shader::shaderFromFile(ResourcePath("f1.txt"), GL_FRAGMENT_SHADER));

    gProgram = new tdogl::Program(shaders);
}

// loads a triangle into the VAO global
static void LoadTriangle() {
    
    mv_location = glGetUniformLocation(gProgram->object(), "mv_matrix");
    proj_location = glGetUniformLocation(gProgram->object(), "proj_matrix");
    
    // make and bind the VAO
    glGenVertexArrays(1, &gVAO);
    glBindVertexArray(gVAO);
    static const GLfloat vertex_positions[] =
    {
        -0.25f,  0.25f, -0.25f,
        -0.25f, -0.25f, -0.25f,
        0.25f, -0.25f, -0.25f,
        
        0.25f, -0.25f, -0.25f,
        0.25f,  0.25f, -0.25f,
        -0.25f,  0.25f, -0.25f,
        
        0.25f, -0.25f, -0.25f,
        0.25f, -0.25f,  0.25f,
        0.25f,  0.25f, -0.25f,
        
        0.25f, -0.25f,  0.25f,
        0.25f,  0.25f,  0.25f,
        0.25f,  0.25f, -0.25f,
        
        0.25f, -0.25f,  0.25f,
        -0.25f, -0.25f,  0.25f,
        0.25f,  0.25f,  0.25f,
        
        -0.25f, -0.25f,  0.25f,
        -0.25f,  0.25f,  0.25f,
        0.25f,  0.25f,  0.25f,
        
        -0.25f, -0.25f,  0.25f,
        -0.25f, -0.25f, -0.25f,
        -0.25f,  0.25f,  0.25f,
        
        -0.25f, -0.25f, -0.25f,
        -0.25f,  0.25f, -0.25f,
        -0.25f,  0.25f,  0.25f,
        
        -0.25f, -0.25f,  0.25f,
        0.25f, -0.25f,  0.25f,
        0.25f, -0.25f, -0.25f,
        
        0.25f, -0.25f, -0.25f,
        -0.25f, -0.25f, -0.25f,
        -0.25f, -0.25f,  0.25f,
        
        -0.25f,  0.25f, -0.25f,
        0.25f,  0.25f, -0.25f,
        0.25f,  0.25f,  0.25f,
        
        0.25f,  0.25f,  0.25f,
        -0.25f,  0.25f,  0.25f,
        -0.25f,  0.25f, -0.25f
    };
    
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER,
                 sizeof(vertex_positions),
                 vertex_positions,
                 GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(0);
    
    glEnable(GL_CULL_FACE);
    glFrontFace(GL_CW);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    // unbind the VBO and VAO
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

// draws a single frame
static void Render(double currentTime) {
#ifdef BREATHING_BG
    const GLfloat color[] =
    { (float)sin(currentTime) * 0.5f + 0.5f, (float)cos(currentTime) * 0.5f + 0.5f, 0.0f, 0.0f };
    glClearBufferfv(GL_COLOR, 0, color);
#else
    static const GLfloat green[] = { 0.0f, 0.25f, 0.0f, 1.0f };
    static const GLfloat one = 1.0f;
    
    glViewport(0, 0, SCREEN_SIZE.x, SCREEN_SIZE.y);
    glClearBufferfv(GL_COLOR, 0, green);
    glClearBufferfv(GL_DEPTH, 0, &one);
#endif
    
    // bind the program (the shaders)
    glUseProgram(gProgram->object());

    // re-bind vao as it is unbind in loadtriangle
    glBindVertexArray(gVAO);
    
//    GLfloat attrib[] = { (float)sin(currentTime) * 0.5f,(float)cos(currentTime) * 0.6f,0.0f, 0.0f };
//    
//    // Update the value of input attribute 0
//    glVertexAttrib4fv(0, attrib);
    
    onResize(SCREEN_SIZE.x, SCREEN_SIZE.y);
    glUniformMatrix4fv(proj_location, 1, GL_FALSE, proj_matrix);
    
#ifdef MANY_CUBES
    int i;
    for (i = 0; i < 24; i++)
    {
        float f = (float)i + (float)currentTime * 0.3f;
        vmath::mat4 mv_matrix = vmath::translate(0.0f, 0.0f, -6.0f) *
        vmath::rotate((float)currentTime * 45.0f, 0.0f, 1.0f, 0.0f) *
        vmath::rotate((float)currentTime * 21.0f, 1.0f, 0.0f, 0.0f) *
        vmath::translate(sinf(2.1f * f) * 2.0f,
                         cosf(1.7f * f) * 2.0f,
                         sinf(1.3f * f) * cosf(1.5f * f) * 2.0f);
        glUniformMatrix4fv(mv_location, 1, GL_FALSE, mv_matrix);
        
        glDrawArrays(GL_TRIANGLES, 0, 36);
        //glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);
        
    }
#else
    float f = (float)currentTime * 0.3f;
    vmath::mat4 mv_matrix = vmath::translate(0.0f, 0.0f, -4.0f) *
    vmath::translate(sinf(2.1f * f) * 0.5f,
                     cosf(1.7f * f) * 0.5f,
                     sinf(1.3f * f) * cosf(1.5f * f) * 2.0f) *
    vmath::rotate((float)currentTime * 45.0f, 0.0f, 1.0f, 0.0f) *
    vmath::rotate((float)currentTime * 81.0f, 1.0f, 0.0f, 0.0f);
    glUniformMatrix4fv(mv_location, 1, GL_FALSE, mv_matrix);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    //glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);
    
#endif
    
    // unbind the VAO
    glBindVertexArray(0);
    
    // unbind the program
    glUseProgram(0);
    
    // swap the display buffers (displays what was just drawn)
    glfwSwapBuffers();
}
//static void LoadTriangle1()
//{
//    mv_location = glGetUniformLocation(gProgram->object(), "mv_matrix");
//    proj_location = glGetUniformLocation(gProgram->object(), "proj_matrix");
//
//    // make and bind the VAO
//    glGenVertexArrays(1, &gVAO);
//    glBindVertexArray(gVAO);
//    
//    static const GLfloat vertex_positions[] =
//    {
//        -0.25f, -0.25f, -0.25f,
//        -0.25f, 0.25f, -0.25f,
//        0.25f, -0.25f, -0.25f,
//        0.25f, 0.25f, -0.25f,
//        0.25f, -0.25f, 0.25f,
//        0.25f, 0.25f, 0.25f,
//        -0.25f, -0.25f, 0.25f,
//        -0.25f, 0.25f, 0.25f,
//    };
//
//    static const GLushort vertex_indices[] =
//    {
//        0, 1, 2,
//        2, 1, 3,
//        2, 3, 4,
//        4, 3, 5,
//        4, 5, 6,
//        6, 5, 7,
//        6, 7, 0,
//        0, 7, 1,
//        6, 0, 2,
//        2, 4, 6,
//        7, 5, 3,
//        7, 3, 1
//    };
//    
//    glGenBuffers(1, &position_buffer);
//    glBindBuffer(GL_ARRAY_BUFFER, position_buffer);
//    glBufferData(GL_ARRAY_BUFFER,
//                 sizeof(vertex_positions),
//                 vertex_positions,
//                 GL_STATIC_DRAW);
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
//    glEnableVertexAttribArray(0);
//    
//    glGenBuffers(1, &index_buffer);
//    glBindBuffer(GL_ARRAY_BUFFER, index_buffer);
//    glBufferData(GL_ARRAY_BUFFER,
//                 sizeof(vertex_indices),
//                 vertex_indices,
//                 GL_STATIC_DRAW);
//    
//    glEnable(GL_CULL_FACE);
//    glFrontFace(GL_CW);
//    
//    glEnable(GL_DEPTH_TEST);
//    glDepthFunc(GL_LEQUAL);
//    
//    // unbind the VBO and VAO
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//    glBindVertexArray(0);
//}

void shutdown()
{
    glDeleteVertexArrays(1, &gVAO);
    glDeleteProgram(gProgram->object());
    glDeleteBuffers(1, &buffer); //???
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
    
    // create buffer and fill it with the points of the triangle
    LoadTriangle();
    
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

