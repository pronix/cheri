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

package org.cheri;

import org.jruby.Ruby;
import org.jruby.RubyModule;
//import org.jruby.runtime.CallbackFactory;
//import org.jruby.runtime.builtin.IRubyObject;

/**
 * 
 * @author Bill Dortch
 *
 */
public class Cheri {
    
    public static final String VERSION = "0.0.9";
    
    public static class CheriVersionException extends RuntimeException {
        public CheriVersionException() {
            super("Incompatible JRuby version for Cheri version " + VERSION);
        }
    }
    
    public static RubyModule createCheriModule(Ruby runtime) {
        RubyModule cheriModule = runtime.defineModule("Cheri");
        RuntimeResources.getResources(runtime).setCheri(cheriModule);
        //CallbackFactory callbackFactory = runtime.callbackFactory(Cheri.class);

        //CheriBuilder.createCheriBuilderModule(runtime, cheriModule);
        //CheriJava.createJavaModule(runtime, cheriModule);
        return cheriModule;
    }

}
