package WxAPISpecification.v1.utils;

// -----( IS Java Code Template v1.2

import com.wm.data.*;
import com.wm.util.Values;
import com.wm.app.b2b.server.Service;
import com.wm.app.b2b.server.ServiceException;
// --- <<IS-START-IMPORTS>> ---
import java.util.regex.Pattern;
// --- <<IS-END-IMPORTS>> ---

public final class java

{
	// ---( internal utility methods )---

	final static java _instance = new java();

	static java _newInstance() { return new java(); }

	static java _cast(Object o) { return (java)o; }

	// ---( server methods )---




	public static final void isValidPackageName (IData pipeline)
        throws ServiceException
	{
		// --- <<IS-START(isValidPackageName)>> ---
		// @sigtype java 3.5
		// [i] field:0:required packageName
		// [i] field:0:required pkgToSkipRegex
		// [o] field:0:required isMatched
		// pipeline
		IDataCursor pipelineCursor = pipeline.getCursor();
		boolean isMatched = false;
			String	packageName = IDataUtil.getString( pipelineCursor, "packageName" );
			String	pkgToSkipRegex = IDataUtil.getString( pipelineCursor, "pkgToSkipRegex" );
			if (packageName == null || packageName.trim().isEmpty()) {
				isMatched = false;
		    }
			isMatched = Pattern.matches(pkgToSkipRegex, packageName);
		
		IDataUtil.put( pipelineCursor,  "isMatched", isMatched );
		pipelineCursor.destroy();
		// --- <<IS-END>> ---

                
	}
}

