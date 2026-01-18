package com.mn.cm.config;

import org.springframework.beans.factory.config.PropertyPlaceholderConfigurer;

public class DecryptionPropertyPlaceholderConfigurer extends PropertyPlaceholderConfigurer {

    @Override
    protected String convertPropertyValue(String originalValue) {
        if (originalValue == null) {
            return null;
        }

        // Expecting values like ENC(somevalue_encrypted)
        if (originalValue.startsWith("ENC(") && originalValue.endsWith(")")) {
            String inner = originalValue.substring(4, originalValue.length() - 1);
            // Simple reversible "decryption": strip a known suffix used in properties
            final String SUFFIX = "_encrypted";
            if (inner.endsWith(SUFFIX)) {
                return inner.substring(0, inner.length() - SUFFIX.length());
            }
            // If suffix not present, just return the inner value as a fallback
            return inner;
        }

        return originalValue;
    }
}
