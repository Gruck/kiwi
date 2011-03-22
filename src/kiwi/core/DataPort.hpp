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

#ifndef KIWI_CORE_READEROUTPUTPORT_HPP
#define KIWI_CORE_READEROUTPUTPORT_HPP

#include <list>
#include "kiwi/utils/Tags.hpp"
#include "kiwi/utils/UnorderedArray.hpp"
#include "kiwi/core/Container.hpp"



namespace kiwi{
namespace core{

class ReaderPort;
class WriterPort;
class Node;


/**
 * @brief Generic output port class for Reader and Writer interface.
 *
 * An instance of this class is hold by a Node for each of it's outputs.
 * Port classes are designed to do most of the external actions on Node/Filter
 * which are doning connections between Nodes and retrieving informations on
 * their input/output data.
 * 
 * Each port has a name which use is facultative has they are truely accessed
 * using an integer index.
 *
 */ 
class DataPort
{
friend class Node;
public:
friend class ReaderPort;
friend class WriterPort;

	// --------------------------------------------------------------------
	/**
	 * @brief Constructor.
	 */ 
	DataPort(Node* myNode);
	//DataPort(Node* myNode, Container* data = 0);
	/**
	 * @brief Returns the index of this port.
	 */ 
	portIndex_t index() const ;
	/**
	 * @brief Returns a pointer to the Node containing this port.
	 */ 
	Node* node() const ;

	/**
	 * @brief Returns true if this port has sub-ports.
	 *
	 * This happens when the port is associated to a composite Container. 
	 */ 
	bool isComposite() const ;

	/**
	 * @brief Returns a reference to the ith sub-port if any.
	 *
	 * If the port is not composite, returns self. Consider it has an undefined
	 * behaviour that must be avoided.
	 */ 
	DataPort& subPort(kiwi::uint32_t i){
		if(i >= _subPorts.size() ){
			Debug::error() << "DataPort::subPort: subPort not found!\n";
			return *this;
		}
		return *_subPorts[i];
	}

	/**
	 * @brief Returns the number of sub-ports (0 if not a composite port).
	 */ 
	kiwi::uint32_t nbSubPorts() const { return _subPorts.size(); }


  /**
	 * @brief Returns this port's Type as a string.
	 */ 
	utils::Tags tags() const;

  virtual bool isEmpty() const = 0;
  	
	bool connect(ReaderPort* port);
	
	bool connect(WriterPort* port);

  /**
	 * @brief returns true if this data port is connected to at least one port
	 * (reader and/or writer ports).
	 */ 
	bool isConnected() const{
		return isConnectedToReader() || isConnectedToWriter();
	}


  /**
	 * @brief Disconnects from the reader port oassed in pa	parameter
	 */ 
	void disconnectReader( ReaderPort* port = 0);
	/**
	 * @brief Disconnects from the writer port oassed in pa	parameter
	 */ 
	void disconnectWriter( WriterPort* port = 0);
	/**
	 * @brief Disconnects this ports from all the ports it is connected to.
	 */ 
	void disconnectAll(){
		disconnectReader(0);
		disconnectWriter(0);
	}

	/**
	 * @brief Tries to return the associated container in a given class type.
	 *
	 * Returns 0 if for some reson the port doesn't have a container (disabled port)
	 * or if the container could not be casted to the requested class type. 
	 */ 
	template<class T>
	T* safeDownCastContainer() {
		ScopedBlockMacro("DataPort::safeDownCastContainer")
		DEBUG_ONLY(
      if( isEmpty() ) Debug::error() << "no Container\n";
			if(!dynamic_cast<T*>( getAbstractContainer() ) )
        Debug::error() << "cast failed\n" ;
			)
		return dynamic_cast<T*>( getAbstractContainer() );
	}

  


  // ---------------------------------------------- Virtual methods
  

  virtual Container* getAbstractContainer() const = 0;

	/**
	 * @brief Port compatibility check based on the type string.
	 */ 
	virtual bool isCompatible(ReaderPort& input);
	virtual bool isCompatible(WriterPort& input);

	/**
	 * @brief returns true if this port is enabled.
	 * 
	 * A port as to be enabloed to be connected. 
	 * By default a port is enabled.
	 */ 
	virtual bool isEnabled() const ;

	/**
	 * @brief returns true if this data port is connected to at least one reader port.
	 */ 
	virtual bool isConnectedToReader( ReaderPort* port = 0) const{
    if(!port) return _connectedReaders.size() > 0;
		return (_connectedReaders.find(port) != -1);
	}

	/**
	 * @brief Returns true if this data port is connected to at least one writer port.
	 */ 
	virtual bool isConnectedToWriter( WriterPort* port = 0 ) const{
    if(!port) return _connectedWriters.size() > 0;
		return (_connectedWriters.find(port) != -1);
	}

	

	
protected:
  /**
	 * @brief Sets this port's container.
	 */ 
	virtual bool setAbstractContainer( Container* data ) = 0;
	
  virtual void connect_impl( ReaderPort* port );
  virtual void disconnect_impl( ReaderPort* port );

  virtual void connect_impl( WriterPort* port );
  virtual void disconnect_impl( WriterPort* port );

  void connectWithoutChecking( ReaderPort* port );
  void connectWithoutChecking( WriterPort* port );

	/**
	 * @brief Used internally by kiwi::core::Node to perform port binding.
	 * 
	 * @see kiwi::core::Node::bindPort
	 */ 
	void bind( DataPort& port );

  /**
   * @brief Unbinds the port if binded.
   *
   * @see void DataPort::bind( DataPort& port )
   */ 
	void unBind();

protected:
	Node* _node;	
private:
	//Container* _container;
  //connections
  utils::UnorderedArray<ReaderPort*> _connectedReaders;
  utils::UnorderedArray<WriterPort*> _connectedWriters;
  //port binding
	utils::UnorderedArray<DataPort*> _linkedOutputPorts;
  //composite data ports
	utils::UnorderedArray<DataPort*> _subPorts;
};


}// namespace
}// namespace

#endif
