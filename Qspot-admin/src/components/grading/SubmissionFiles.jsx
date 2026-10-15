import React from 'react';
import { FiExternalLink, FiFile } from 'react-icons/fi';
import { fileUrl } from '../../utils/gradebook';

// A learner's attached files: audio plays here, images show here, anything
// else opens in a new tab.
const SubmissionFiles = ({ files }) => {
  if (!files?.length) return null;
  return (
    <div className="space-y-2">
      {files.map((file, index) => {
        const url = fileUrl(file.url);
        const type = String(file.mimeType || '');
        return (
          <div key={`${file.url}-${index}`} className="rounded-xl border border-white/10 bg-white/[0.03] p-3">
            <div className="mb-2 flex items-center gap-2 text-xs text-white/60">
              <FiFile className="shrink-0 text-[#EFB078]" />
              <span className="min-w-0 truncate">{file.name}</span>
            </div>
            {type.startsWith('audio/') ? (
              <audio controls preload="none" src={url} className="w-full" />
            ) : type.startsWith('image/') ? (
              <a href={url} target="_blank" rel="noreferrer"><img src={url} alt={file.name} className="max-h-72 w-full rounded-lg object-contain" /></a>
            ) : (
              <a href={url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-sm font-semibold text-[#EFB078] hover:underline">
                Open file <FiExternalLink size={13} />
              </a>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default SubmissionFiles;
