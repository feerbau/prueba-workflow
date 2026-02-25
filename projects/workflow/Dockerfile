FROM gcr.io/oss-fuzz-base/base-builder-javascript

# Install Node.js (workflow requires Node.js)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install pnpm (workflow uses pnpm)
RUN npm install -g pnpm

# Clone the workflow repository
RUN git clone --depth 1 https://github.com/vercel/workflow $SRC/workflow

WORKDIR $SRC/workflow

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy build script
COPY build.sh $SRC/
