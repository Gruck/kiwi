// Copyright (c) 2010 Nicolas Silva
// All rights reserved.
//      Redistribution and use in source and binary forms, with or without
//      modification, are permitted provided that the following conditions are
//      met:
//      
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above
//        copyright notice, this list of conditions and the following disclaimer
//        in the documentation and/or other materials provided with the
//        distribution.
//      * Neither the name of the  nor the names of its
//        contributors may be used to endorse or promote products derived from
//        this software without specific prior written permission.
//      
//      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//      A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#pragma once

#ifndef KIWI_RESOURCE_HPP
#define KIWI_RESOURCE_HPP

#include "kiwi/core/Node.hpp"


namespace kiwi
{
namespace core
{

/**
 * @brief The base class for containers.
 * 
 */ 
class Container : public Node
{
public:
	static const uint32_t UNAVAILABLE = 0;
	
	//Container() : Node() {}
	virtual kiwi::uint32_t memoryConsumption() const { return UNAVAILABLE; } ;
};


/**
 * @brief helper macro that produces typedef classType ReaderType;
 * 
 * Some filters that have template a parameter on the (Container) input type need
 * to know at compilation time the Container's Reader type to instanciate it
 * correctly. This macro should be used in the public part of every Container class
 * declaration.
 */ 
#define ReaderTypeMacro(classType) typedef classType ReaderType;

/**
 * @brief helper macro that produces typedef classType WriterType;
 * 
 * Some filters that have a template parameter on the (Container) input type need
 * to know at compilation time the Container's Writer type to instanciate it
 * correctly. This macro should be used in the public part of every Container class
 * declaration. 
 */ 
#define WriterTypeMacro(classType) typedef classType WriterType;

/**
 * @brief helper macro that produces typedef classType ReaderType;
 * 
 * Some filters that have template a parameter on the (Container) input type need
 * to know at compilation time the Container's Reader type to instanciate it
 * correctly. This macro should be used in the public part of every class
 * declaration of containers that are iterable. 
 */ 
#define IteratorTypeMacro(classType) typedef classType IteratorType;



} //namespace
} //namespace

#endif
