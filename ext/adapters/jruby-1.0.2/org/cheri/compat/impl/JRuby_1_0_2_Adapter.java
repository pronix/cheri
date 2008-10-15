/***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2007,2008 William N Dortch <bill.dortch@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 ***** END LICENSE BLOCK *****/

package org.cheri.compat.impl;

import org.cheri.compat.JRubyVersionAdapter;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;

public class JRuby_1_0_2_Adapter extends JRubyVersionAdapter {

    public JRuby_1_0_2_Adapter() {
    }

    public String getAsSymbolString(Ruby runtime, Object obj) {
        if (obj instanceof RubySymbol) {
            return ((RubySymbol)obj).asSymbol();
        } else if (obj instanceof RubyString) {
            return ((RubyString)obj).toString();
        }
        // FIXME: non-standard TypeError message
        throw runtime.newTypeError("not a symbol: " + obj);
    }
    
    public String getAsInternedSymbolString(Ruby runtime, Object obj) {
        if (obj instanceof RubySymbol) {
            return ((RubySymbol)obj).asSymbol().intern();
        } else if (obj instanceof RubyString) {
            return ((RubyString)obj).toString().intern();
        }
        // FIXME: non-standard TypeError message
        throw runtime.newTypeError("not a symbol: " + obj);
    }
    
    public Object getInstanceVariable(Ruby runtime, Object self, String name) {
        if (self instanceof IRubyObject) {
            return ((IRubyObject)self).getInstanceVariable(name);
        }
        throw newCheriVersionError(runtime);
    }
    
    public Object fastGetInstanceVariable(Ruby runtime, Object self, String internedName) {
        if (self instanceof IRubyObject) {
            return ((IRubyObject)self).getInstanceVariable(internedName);
        }
        throw newCheriVersionError(runtime);
    }
    
    public Object getBlockAsProc(Ruby runtime, Object block) {
        if (block instanceof Block) {
            return runtime.newProc(Block.Type.PROC, (Block)block);
        }
        throw newCheriVersionError(runtime);
    }

    public boolean isKindOf(Ruby runtime, Object self, Object module) {
        if (self instanceof IRubyObject && module instanceof RubyModule) {
            return ((IRubyObject)self).getMetaClass().hasModuleInHierarchy((RubyModule)module);
        }
        throw newCheriVersionError(runtime);
    }

    

}
